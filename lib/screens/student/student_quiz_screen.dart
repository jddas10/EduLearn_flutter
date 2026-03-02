import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../auth/api_service.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});
  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnim;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Active', 'Completed'];
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_selectedFilter == 0) return _quizzes;
    return _quizzes.where((q) => q['status'] == _filters[_selectedFilter]).toList();
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _headerAnim = CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);
    _headerController.forward();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final res = await QuizApi.getStudentQuizzes();
      if (res['success'] == true && mounted) {
        final List raw = res['quizzes'] ?? [];
        const colors = [Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF00D4AA), Color(0xFFFFB347)];
        const icons = ['📐', '📝', '🔬', '🌍'];
        setState(() {
          _quizzes = List.generate(raw.length, (i) {
            final q = raw[i];
            final done = q['myStatus'] == 'Completed';
            return {
              'id': q['id'],
              'title': q['title'] ?? 'Untitled',
              'questions': q['question_count'] ?? 0,
              'totalMarks': q['total_marks'] ?? 0,
              'duration': 20,
              'status': done ? 'Completed' : 'Active',
              'dueDate': done ? 'Score: ${q['myScore']}/${q['total_marks']}' : 'Tap to start',
              'color': colors[i % colors.length],
              'icon': icons[i % icons.length],
              'myScore': done ? (q['myScore'] ?? 0) : null,
              'attempted': done,
            };
          });
          _isLoading = false;
        });
        _listController.forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressSummary(),
                _buildFilterTabs(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                      : _quizzes.isEmpty
                      ? Center(child: Text('No quizzes available', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)))
                      : _buildQuizList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(_headerAnim),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)]).createShader(bounds),
                child: const Text('My Quizzes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final pending = _quizzes.where((q) => q['status'] == 'Active').length;
    final completed = _quizzes.where((q) => q['status'] == 'Completed').length;
    int totalScore = 0;
    int totalMarks = 0;
    for (final q in _quizzes) {
      if (q['attempted'] == true && q['myScore'] != null) {
        totalScore += (q['myScore'] as int);
        totalMarks += (q['totalMarks'] as int);
      }
    }
    final avg = totalMarks > 0 ? '${(totalScore / totalMarks * 100).toInt()}%' : '-';
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (ctx, child) => Opacity(opacity: _headerAnim.value, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF6C63FF).withValues(alpha: 0.18), const Color(0xFF00D4AA).withValues(alpha: 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(child: _summaryItem('$pending', 'Pending', const Color(0xFFFFB347))),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(child: _summaryItem('$completed', 'Completed', const Color(0xFF00D4AA))),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(child: _summaryItem(avg, 'Avg Score', const Color(0xFF6C63FF))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 0, 4),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, i) {
            final selected = _selectedFilter == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(_filters[i], style: TextStyle(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.45), fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    final quizzes = _filteredQuizzes;
    return RefreshIndicator(
      onRefresh: _fetchQuizzes,
      color: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF131929),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              final delay = index * 0.15;
              final animValue = math.max(0.0, math.min(1.0, (_listController.value - delay) / (1.0 - delay)));
              final curve = Curves.easeOutCubic.transform(animValue.clamp(0.0, 1.0));
              return Opacity(opacity: curve, child: Transform.translate(offset: Offset(0, 40 * (1 - curve)), child: child));
            },
            child: _buildQuizCard(quizzes[index]),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final color = quiz['color'] as Color;
    final status = quiz['status'] as String;
    final attempted = quiz['attempted'] as bool;
    final myScore = quiz['myScore'] as int?;
    final totalMarks = quiz['totalMarks'] as int;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (status == 'Active') {
      statusColor = const Color(0xFF00D4AA);
      statusLabel = 'Active';
      statusIcon = Icons.radio_button_checked;
    } else {
      statusColor = const Color(0xFF6C63FF);
      statusLabel = 'Done';
      statusIcon = Icons.check_circle;
    }
    return GestureDetector(
      onTap: () {
        if (status == 'Active' && !attempted) {
          _startQuiz(quiz);
        } else if (status == 'Completed') {
          _viewResult(quiz);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.3)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(quiz['icon'], style: const TextStyle(fontSize: 22)))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(quiz['title'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(quiz['dueDate'], style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, color: statusColor, size: 10), const SizedBox(width: 4), Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700))]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    _chip(Icons.help_outline, '${quiz['questions']} Questions', color),
                    const SizedBox(width: 14),
                    _chip(Icons.star_outline, '$totalMarks Marks', color),
                  ]),
                  const SizedBox(height: 12),
                  if (status == 'Completed' && myScore != null) _scoreBar(myScore, totalMarks, color),
                ],
              ),
            ),
            if (status == 'Active' && !attempted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text('Start Quiz', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]),
                ),
              ),
            if (status == 'Completed')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                child: Row(children: [Icon(Icons.visibility_outlined, color: color, size: 16), const SizedBox(width: 6), Text('View Results', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)), const Spacer(), Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 18)]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color.withValues(alpha: 0.7), size: 13),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _scoreBar(int score, int total, Color color) {
    final pct = total > 0 ? score / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Your Score: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        Text('$score/$total', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)), minHeight: 5)),
    ]);
  }

  void _startQuiz(Map<String, dynamic> quiz) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: QuizAttemptScreen(quiz: quiz)), transitionDuration: const Duration(milliseconds: 400))).then((_) => _fetchQuizzes());
  }

  void _viewResult(Map<String, dynamic> quiz) {
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: QuizResultScreen(quiz: quiz)), transitionDuration: const Duration(milliseconds: 400)));
  }
}

class QuizAttemptScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizAttemptScreen({super.key, required this.quiz});
  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _questionEntryController;
  late Animation<double> _questionEntryAnim;
  int _currentIndex = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  late Timer _timer;
  int _secondsLeft = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _cheated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = (widget.quiz['duration'] as int? ?? 20) * 60;
    _questionEntryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _questionEntryAnim = CurvedAnimation(parent: _questionEntryController, curve: Curves.easeOutCubic);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) { _secondsLeft--; } else { t.cancel(); _submitQuiz(); }
      });
    });
    _loadQuestions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _cheated = true;
      _submitQuiz();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final res = await QuizApi.getQuizQuestions(widget.quiz['id'] as int);
      if (res['success'] == true && mounted) {
        final List raw = res['questions'] ?? [];
        setState(() {
          _questions = raw.map<Map<String, dynamic>>((q) => {
            'id': q['id'],
            'question': q['questionText'] ?? '',
            'options': [q['optA'] ?? '', q['optB'] ?? '', q['optC'] ?? '', q['optD'] ?? ''],
            'marks': q['marks'] ?? 1,
          }).toList();
          _isLoading = false;
        });
        _questionEntryController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _questionEntryController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 300) return const Color(0xFF00D4AA);
    if (_secondsLeft > 60) return const Color(0xFFFFB347);
    return const Color(0xFFFF6584);
  }

  void _selectAnswer(String answer) {
    HapticFeedback.selectionClick();
    setState(() { _selectedAnswer = answer; _answers[_currentIndex] = answer; });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      HapticFeedback.lightImpact();
      _questionEntryController.reset();
      setState(() { _currentIndex++; _selectedAnswer = _answers[_currentIndex]; });
      _questionEntryController.forward();
    } else {
      _confirmSubmit();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      _questionEntryController.reset();
      setState(() { _currentIndex--; _selectedAnswer = _answers[_currentIndex]; });
      _questionEntryController.forward();
    }
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _timer.cancel();
    HapticFeedback.heavyImpact();
    final Map<String, String> apiAnswers = {};
    final optLabels = ['A', 'B', 'C', 'D'];
    for (final entry in _answers.entries) {
      final q = _questions[entry.key];
      final opts = q['options'] as List;
      final idx = opts.indexOf(entry.value);
      if (idx >= 0) apiAnswers[q['id'].toString()] = optLabels[idx];
    }
    try {
      final res = await QuizApi.submitQuiz(quizId: widget.quiz['id'] as int, answers: apiAnswers, cheated: _cheated);
      if (res['success'] == true && mounted) {
        final review = res['review'] as List? ?? [];
        final correctMap = <int, String>{};
        for (final r in review) correctMap[r['questionId']] = r['correctOpt'];
        final resultData = Map<String, dynamic>.from(widget.quiz);
        resultData['myScore'] = res['score'] ?? 0;
        resultData['cheated'] = _cheated;
        resultData['answers'] = _answers;
        resultData['questions'] = _questions.asMap().entries.map((e) {
          final q = e.value;
          final correctLetter = correctMap[q['id']] ?? 'A';
          final opts = q['options'] as List;
          final correctIdx = optLabels.indexOf(correctLetter);
          return {'question': q['question'], 'options': opts, 'correct': correctIdx >= 0 && correctIdx < opts.length ? opts[correctIdx] : opts[0], 'points': q['marks']};
        }).toList();
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: QuizResultScreen(quiz: resultData)), transitionDuration: const Duration(milliseconds: 500)));
      } else {
        _isSubmitting = false;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Submit failed'), backgroundColor: const Color(0xFFFF6584), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    } catch (_) {
      _isSubmitting = false;
    }
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Quiz?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('You have answered ${_answers.length}/${_questions.length} questions.', style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C63FF)))),
          TextButton(onPressed: () { Navigator.pop(ctx); _submitQuiz(); }, child: const Text('Submit', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _questions.isEmpty) {
      return Scaffold(backgroundColor: const Color(0xFF0A0E1A), body: Center(child: _isLoading ? const CircularProgressIndicator(color: Color(0xFF6C63FF)) : const Text('No questions found', style: TextStyle(color: Colors.white54))));
    }
    final q = _questions[_currentIndex];
    final color = widget.quiz['color'] as Color;
    final progress = (_currentIndex + 1) / _questions.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cheated = true;
          _submitQuiz();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _BgPainter())),
            SafeArea(
              child: Column(children: [
                _buildAttemptHeader(color, progress),
                Expanded(
                  child: FadeTransition(
                    opacity: _questionEntryAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(_questionEntryAnim),
                      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 120), children: [_buildQuestionCard(q, color), const SizedBox(height: 16), _buildOptions(q, color), const SizedBox(height: 20), _buildQuestionNav()]),
                    ),
                  ),
                ),
              ]),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav(color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptHeader(Color color, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () {
              _cheated = true;
              _submitQuiz();
            },
            child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))), child: const Icon(Icons.close, color: Colors.white, size: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.quiz['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Q${_currentIndex + 1} of ${_questions.length}', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _timerColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: _timerColor.withOpacity(0.3))),
            child: Row(children: [Icon(Icons.timer_outlined, color: _timerColor, size: 15), const SizedBox(width: 5), Text(_timeString, style: TextStyle(color: _timerColor, fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]))]),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 5)),
      ]),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFF131929), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.25)), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('Q${_currentIndex + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Text('${q['marks']} pts', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 12))),
        ]),
        const SizedBox(height: 16),
        Text(q['question'], style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: -0.2)),
      ]),
    );
  }

  Widget _buildOptions(Map<String, dynamic> q, Color color) {
    final options = q['options'] as List;
    final labels = ['A', 'B', 'C', 'D'];
    final optColors = [const Color(0xFF6C63FF), const Color(0xFF00D4AA), const Color(0xFFFFB347), const Color(0xFFFF6584)];
    return Column(
      children: List.generate(options.length, (i) {
        if ((options[i] as String).isEmpty) return const SizedBox.shrink();
        final opt = options[i] as String;
        final selected = _selectedAnswer == opt;
        final optColor = optColors[i];
        return GestureDetector(
          onTap: () => _selectAnswer(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: selected ? optColor.withOpacity(0.15) : const Color(0xFF131929), borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? optColor : Colors.white.withOpacity(0.08), width: selected ? 1.5 : 1), boxShadow: selected ? [BoxShadow(color: optColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : []),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 200), width: 34, height: 34, decoration: BoxDecoration(color: selected ? optColor : optColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(labels[i], style: TextStyle(color: selected ? Colors.white : optColor, fontWeight: FontWeight.w800, fontSize: 14)))),
              const SizedBox(width: 14),
              Expanded(child: Text(opt, style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, height: 1.4))),
              if (selected) Icon(Icons.check_circle, color: optColor, size: 20),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildQuestionNav() {
    return Wrap(spacing: 8, runSpacing: 8, children: List.generate(_questions.length, (i) {
      final answered = _answers.containsKey(i);
      final current = _currentIndex == i;
      return GestureDetector(
        onTap: () { _questionEntryController.reset(); setState(() { _currentIndex = i; _selectedAnswer = _answers[i]; }); _questionEntryController.forward(); },
        child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 38, height: 38,
          decoration: BoxDecoration(color: current ? const Color(0xFF6C63FF) : answered ? const Color(0xFF00D4AA).withOpacity(0.2) : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: current ? const Color(0xFF6C63FF) : answered ? const Color(0xFF00D4AA) : Colors.white.withOpacity(0.1), width: current ? 0 : 1)),
          child: Center(child: Text('${i + 1}', style: TextStyle(color: current ? Colors.white : answered ? const Color(0xFF00D4AA) : Colors.white.withOpacity(0.4), fontWeight: FontWeight.w700, fontSize: 13))),
        ),
      );
    }));
  }

  Widget _buildBottomNav(Color color) {
    final isLast = _currentIndex == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF0A0E1A).withOpacity(0.0), const Color(0xFF0A0E1A)])),
      child: Row(children: [
        if (_currentIndex > 0)
          GestureDetector(onTap: _prev, child: Container(height: 52, width: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _isSubmitting ? null : (isLast ? _confirmSubmit : _next),
            child: Container(height: 52,
              decoration: BoxDecoration(gradient: isLast ? const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF00A878)]) : LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: (isLast ? const Color(0xFF00D4AA) : color).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_isSubmitting) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else ...[Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded, color: Colors.white, size: 20), const SizedBox(width: 8), Text(isLast ? 'Submit Quiz' : 'Next Question', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizResultScreen({super.key, required this.quiz});
  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _scoreController;
  late Animation<double> _entryAnim;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scoreController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _scoreAnim = CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic);
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _scoreController.forward());
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final myScore = quiz['myScore'] as int? ?? 0;
    final totalMarks = quiz['totalMarks'] as int;
    final color = quiz['color'] as Color;
    final pct = totalMarks > 0 ? myScore / totalMarks : 0.0;
    final questions = quiz['questions'] as List<Map<String, dynamic>>? ?? [];
    final answers = quiz['answers'] as Map<int, String>? ?? {};
    String grade; Color gradeColor; String emoji;
    if (pct >= 0.9) { grade = 'A+'; gradeColor = const Color(0xFF00D4AA); emoji = '🏆'; }
    else if (pct >= 0.75) { grade = 'A'; gradeColor = const Color(0xFF6C63FF); emoji = '🌟'; }
    else if (pct >= 0.6) { grade = 'B'; gradeColor = const Color(0xFFFFB347); emoji = '👍'; }
    else { grade = 'C'; gradeColor = const Color(0xFFFF6584); emoji = '💪'; }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)]).createShader(bounds), child: const Text('Quiz Result', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5))),
                  ]),
                ),
                Expanded(
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 40), children: [
                    AnimatedBuilder(
                      animation: _scoreAnim,
                      builder: (ctx, child) => Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [gradeColor.withValues(alpha: 0.15), const Color(0xFF131929)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: gradeColor.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: gradeColor.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                        ),
                        child: Column(children: [
                          Text(emoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${(myScore * _scoreAnim.value).toInt()}', style: TextStyle(color: gradeColor, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2)),
                            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('/$totalMarks', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 24, fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: gradeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: gradeColor.withValues(alpha: 0.3))),
                            child: Text('Grade $grade  •  ${(pct * 100).toInt()}%', style: TextStyle(color: gradeColor, fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct * _scoreAnim.value, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation<Color>(gradeColor), minHeight: 10)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsRow(questions, answers),
                    const SizedBox(height: 20),
                    if (questions.isNotEmpty) ...[
                      Text('Answer Review', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      ...List.generate(questions.length, (i) => _buildAnswerRow(i, questions[i], answers[i])),
                    ],
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () { HapticFeedback.mediumImpact(); Navigator.popUntil(context, (route) => route.isFirst); },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 7))]),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_outlined, color: Colors.white, size: 20), SizedBox(width: 10), Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2))]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Map<String, dynamic>> questions, Map<int, String> answers) {
    int correct = 0; int wrong = 0; int skipped = 0;
    for (int i = 0; i < questions.length; i++) {
      if (!answers.containsKey(i)) { skipped++; }
      else if (answers[i] == questions[i]['correct']) { correct++; }
      else { wrong++; }
    }
    return Row(children: [
      _resultStat('$correct', 'Correct', const Color(0xFF00D4AA), Icons.check_circle_outline),
      const SizedBox(width: 10),
      _resultStat('$wrong', 'Wrong', const Color(0xFFFF6584), Icons.cancel_outlined),
      const SizedBox(width: 10),
      _resultStat('$skipped', 'Skipped', const Color(0xFFFFB347), Icons.remove_circle_outline),
    ]);
  }

  Widget _resultStat(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildAnswerRow(int i, Map<String, dynamic> q, String? myAnswer) {
    final correct = q['correct'] as String;
    final isCorrect = myAnswer == correct;
    final isSkipped = myAnswer == null;
    Color indicatorColor; IconData indicatorIcon;
    if (isSkipped) { indicatorColor = const Color(0xFFFFB347); indicatorIcon = Icons.remove_circle; }
    else if (isCorrect) { indicatorColor = const Color(0xFF00D4AA); indicatorIcon = Icons.check_circle; }
    else { indicatorColor = const Color(0xFFFF6584); indicatorIcon = Icons.cancel; }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF131929), borderRadius: BorderRadius.circular(14), border: Border.all(color: indicatorColor.withValues(alpha: 0.15))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: indicatorColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)), child: Text('Q${i + 1}', style: TextStyle(color: indicatorColor, fontWeight: FontWeight.w800, fontSize: 11))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q['question'], style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          if (!isSkipped && !isCorrect) Text('Your answer: $myAnswer', style: const TextStyle(color: Color(0xFFFF6584), fontSize: 11, fontWeight: FontWeight.w500)),
          Text(isSkipped ? 'Not attempted' : 'Correct: $correct', style: TextStyle(color: isSkipped ? const Color(0xFFFFB347) : const Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        Icon(indicatorIcon, color: indicatorColor, size: 20),
      ]),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF6C63FF).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 180, paint);
    paint.color = const Color(0xFF00D4AA).withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), 140, paint);
    paint.color = const Color(0xFFFF6584).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.85), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}