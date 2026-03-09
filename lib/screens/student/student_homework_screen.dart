import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../auth/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class StudentHomeworkItem {
  final int    id;
  final String title;
  final String description;
  final String className;
  final String subject;
  final Color  subjectColor;
  final String subjectIcon;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<Map<String, dynamic>> attachments; // {file_name, file_url}
  final bool   isSubmitted;
  final String? submittedNote;
  final String? submittedFile;
  final DateTime? submittedAt;

  StudentHomeworkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.className,
    required this.subject,
    required this.subjectColor,
    required this.subjectIcon,
    required this.dueDate,
    required this.createdAt,
    required this.attachments,
    required this.isSubmitted,
    this.submittedNote,
    this.submittedFile,
    this.submittedAt,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isSubmitted;
  bool get isDueSoon =>
      !isOverdue &&
          !isSubmitted &&
          dueDate.difference(DateTime.now()).inHours < 24;
}

const _kColors = [
  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6584),
  Color(0xFFFFB347), Color(0xFF00D4FF), Color(0xFFFF8C42),
];

Color _hexColor(String? hex, int idx) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    try { return Color(int.parse('FF${hex.substring(1)}', radix: 16)); }
    catch (_) {}
  }
  return _kColors[idx % _kColors.length];
}

String _fmtDate(DateTime dt) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month-1]}, ${dt.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double>   _headerAnim;

  List<StudentHomeworkItem> _homeworks = [];
  bool   _isLoading = true;
  String _filter    = 'All';

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    _fetchHomeworks();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeworks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await HomeworkApi.getStudentHomeworks();
      if (res['success'] == true && mounted) {
        final List raw = res['homeworks'] ?? [];
        setState(() {
          _homeworks = List.generate(raw.length, (i) {
            final h = raw[i] as Map<String, dynamic>;

            // ✅ FIX: Parse attachments as list of {file_name, file_url} maps
            final rawAttachments = h['attachments'];
            List<Map<String, dynamic>> attachments = [];
            if (rawAttachments is List) {
              for (final a in rawAttachments) {
                if (a is Map<String, dynamic>) {
                  attachments.add(a);
                } else if (a is String) {
                  attachments.add({'file_name': a, 'file_url': ''});
                }
              }
            }

            return StudentHomeworkItem(
              id:           (h['id'] as num).toInt(),
              title:        h['title']        as String? ?? '',
              description:  h['description']  as String? ?? '',
              className:    h['class_name']   as String? ?? '',
              subject:      h['subject']      as String? ?? '',
              subjectColor: _hexColor(h['subject_color'] as String?, i),
              subjectIcon:  h['icon']         as String? ?? '📚',
              dueDate:      DateTime.parse(h['due_date'] as String),
              createdAt:    DateTime.parse(h['created_at'] as String),
              attachments:  attachments,
              isSubmitted:  h['isSubmitted']  as bool? ?? false,
              submittedNote: h['submitted_note'] as String?,
              submittedFile: h['submitted_file'] as String?,
              submittedAt: h['submitted_at'] != null
                  ? DateTime.tryParse(h['submitted_at'].toString())
                  : null,
            );
          });
          _isLoading = false;
        });
        _listCtrl..reset()..forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('fetchHomeworks error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StudentHomeworkItem> get _filtered {
    switch (_filter) {
      case 'Pending':   return _homeworks.where((h) => !h.isSubmitted && !h.isOverdue).toList();
      case 'Submitted': return _homeworks.where((h) => h.isSubmitted).toList();
      case 'Overdue':   return _homeworks.where((h) => h.isOverdue).toList();
      default:          return _homeworks;
    }
  }

  // ✅ FIX: Open/download file via url_launcher
  Future<void> _openFile(String fileUrl, String fileName) async {
    if (fileUrl.isEmpty) {
      _showSnack('File URL not available', const Color(0xFFFF6584));
      return;
    }
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Cannot open file. Try downloading manually.', const Color(0xFFFF6584));
      }
    } catch (e) {
      _showSnack('Error opening file: $e', const Color(0xFFFF6584));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          CustomPaint(painter: _BgPainter(), size: Size.infinite),
          SafeArea(
            child: FadeTransition(
              opacity: _headerAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C6FF)))
                        : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                      onRefresh: _fetchHomeworks,
                      color: const Color(0xFF00C6FF),
                      backgroundColor: const Color(0xFF131929),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          return AnimatedBuilder(
                            animation: _listCtrl,
                            builder: (ctx, child) {
                              final delay = i * 0.08;
                              final v = math.max(0.0, math.min(1.0,
                                  (_listCtrl.value - delay) / (1.0 - delay)));
                              final c = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
                              return Opacity(
                                opacity: v.clamp(0.0, 1.0),
                                child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - c)), child: child),
                              );
                            },
                            child: _buildHomeworkCard(_filtered[i]),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pending   = _homeworks.where((h) => !h.isSubmitted && !h.isOverdue).length;
    final submitted = _homeworks.where((h) => h.isSubmitted).length;
    final overdue   = _homeworks.where((h) => h.isOverdue).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]).createShader(b),
                    child: const Text('My Homework',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: -0.5)),
                  ),
                  Text('Track & Submit',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _fetchHomeworks,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.25)),
                ),
                child: const Row(children: [
                  Icon(Icons.refresh, color: Color(0xFF00C6FF), size: 14),
                  SizedBox(width: 5),
                  Text('Refresh', style: TextStyle(color: Color(0xFF00C6FF),
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF00C6FF).withOpacity(0.1),
                const Color(0xFF0072FF).withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.2)),
            ),
            child: Row(children: [
              _statChip('$pending', 'Pending', const Color(0xFFFFB347)),
              _vDiv(),
              _statChip('$submitted', 'Submitted', const Color(0xFF00D4AA)),
              _vDiv(),
              _statChip('$overdue', 'Overdue', const Color(0xFFFF6584)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String val, String label, Color color) => Expanded(
    child: Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _vDiv() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.08));

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Pending', 'Submitted', 'Overdue'].map((f) {
            final selected = _filter == f;
            return GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(f, style: TextStyle(
                    color: selected ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('No homework here',
              style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _fetchHomeworks,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00C6FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.3)),
              ),
              child: const Text('Retry', style: TextStyle(
                  color: Color(0xFF00C6FF), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(StudentHomeworkItem hw) {
    final dueBadgeColor = hw.isSubmitted
        ? const Color(0xFF00D4AA)
        : hw.isOverdue
        ? const Color(0xFFFF6584)
        : hw.isDueSoon
        ? const Color(0xFFFFB347)
        : const Color(0xFF6C63FF);

    final dueText = hw.isSubmitted ? 'Submitted ✓'
        : hw.isOverdue ? 'Overdue'
        : hw.isDueSoon ? 'Due Soon'
        : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hw.subjectColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: hw.subjectColor.withOpacity(0.07),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Top color bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [hw.subjectColor, hw.subjectColor.withOpacity(0.3)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject + badge row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: hw.subjectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        hw.subject.isNotEmpty
                            ? hw.subject.substring(0, math.min(3, hw.subject.length)).toUpperCase()
                            : 'HW',
                        style: TextStyle(color: hw.subjectColor,
                            fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(hw.className,
                        style: TextStyle(color: Colors.white.withOpacity(0.5),
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: dueBadgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dueBadgeColor.withOpacity(0.3))),
                    child: Text(dueText,
                        style: TextStyle(color: dueBadgeColor,
                            fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 12),

                // Title + desc
                Text(hw.title,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(hw.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.4),
                        fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),

                // ✅ FIX: Attachments with DOWNLOAD button
                if (hw.attachments.isNotEmpty) ...[
                  Text('ATTACHMENTS',
                      style: TextStyle(color: Colors.white.withOpacity(0.35),
                          fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  ...hw.attachments.map((att) {
                    final fileName = att['file_name'] as String? ?? 'File';
                    final fileUrl  = att['file_url']  as String? ?? '';
                    final isPdf    = fileName.toLowerCase().endsWith('.pdf');
                    final isImage  = fileName.toLowerCase().endsWith('.jpg') ||
                        fileName.toLowerCase().endsWith('.jpeg') ||
                        fileName.toLowerCase().endsWith('.png');

                    return GestureDetector(
                      onTap: () => _openFile(fileUrl, fileName),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: hw.subjectColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: hw.subjectColor.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_outlined
                                : isImage ? Icons.image_outlined
                                : Icons.insert_drive_file_outlined,
                            color: hw.subjectColor, size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(fileName,
                                style: TextStyle(color: Colors.white.withOpacity(0.8),
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hw.subjectColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.download_outlined, color: hw.subjectColor, size: 13),
                              const SizedBox(width: 4),
                              Text('Open', style: TextStyle(
                                  color: hw.subjectColor, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // Submitted info
                if (hw.isSubmitted && hw.submittedAt != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Submitted on ${_fmtDate(hw.submittedAt!)}',
                                style: const TextStyle(color: Color(0xFF00D4AA),
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            if (hw.submittedNote != null && hw.submittedNote!.isNotEmpty)
                              Text('"${hw.submittedNote}"',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                                      fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.3), size: 13),
              const SizedBox(width: 5),
              Text(_fmtDate(hw.dueDate),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              const Spacer(),
              if (!hw.isSubmitted && !hw.isOverdue)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _SubmitHomeworkSheet(
                        hw: hw,
                        onSubmitted: _fetchHomeworks,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [hw.subjectColor, hw.subjectColor.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                          color: hw.subjectColor.withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.upload_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text('Submit', style: TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                )
              else if (hw.isOverdue)
                Text('Overdue', style: TextStyle(
                    color: const Color(0xFFFF6584).withOpacity(0.7),
                    fontSize: 12, fontWeight: FontWeight.w600))
              else
                Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 14),
                  const SizedBox(width: 4),
                  const Text('Submitted', style: TextStyle(
                      color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Submit Sheet ──────────────────────────────────────────────────────────────

class _SubmitHomeworkSheet extends StatefulWidget {
  final StudentHomeworkItem hw;
  final VoidCallback onSubmitted;
  const _SubmitHomeworkSheet({required this.hw, required this.onSubmitted});

  @override
  State<_SubmitHomeworkSheet> createState() => _SubmitHomeworkSheetState();
}

class _SubmitHomeworkSheetState extends State<_SubmitHomeworkSheet> {
  final _noteCtrl = TextEditingController();
  String? _filePath;
  String? _fileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _pickFile() async {
    HapticFeedback.lightImpact();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_noteCtrl.text.trim().isEmpty && _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: const Text('Add a note or attach a file to submit.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final res = await HomeworkApi.submitHomework(
      homeworkId: widget.hw.id,
      note:       _noteCtrl.text.trim(),
      filePath:   _filePath,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (res['success'] == true && mounted) {
      widget.onSubmitted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF00D4AA),
        content: Text('✓ Homework submitted!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: Text(res['message'] ?? 'Submission failed'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hw    = widget.hw;
    final color = hw.subjectColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(hw.subjectIcon,
                    style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Submit Homework', style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(hw.title, style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ])),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: Colors.white.withOpacity(0.4)),
              ),
            ]),
            const SizedBox(height: 20),

            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _filePath != null
                      ? color.withOpacity(0.1)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _filePath != null
                        ? color.withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.attach_file,
                      color: _filePath != null ? color : Colors.white.withOpacity(0.4),
                      size: 18),
                  const SizedBox(width: 8),
                  Text(_fileName ?? 'Attach File (PDF / Image)',
                      style: TextStyle(
                          color: _filePath != null ? color : Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.upload_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Submit Homework', style: TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Background Painter ────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF00C6FF).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFF0072FF).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.55), 140, p);
    p.color = const Color(0xFF00D4AA).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.88), 110, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}