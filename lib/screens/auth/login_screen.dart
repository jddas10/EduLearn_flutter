import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../app/routes.dart';
import '../../screens/auth/api_service.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _userFocused = false;
  bool _passFocused = false;
  bool _loading = false;

  late final AnimationController _orbCtl;
  late final AnimationController _particleCtl;
  late final AnimationController _introCtl;
  late final AnimationController _btnCtl;
  late final AnimationController _shakeCtl;

  late final Animation<double> _badgeFade;
  late final Animation<Offset> _badgeSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _btnScale;
  late final Animation<double> _btnGlow;
  late final Animation<double> _shake;

  final List<_Particle> _particles = List.generate(24, (i) => _Particle(seed: i));

  @override
  void initState() {
    super.initState();

    _orbCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _particleCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _introCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _badgeFade = CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _badgeSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
    ));

    _btnCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.03), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _btnCtl, curve: Curves.easeInOut));
    _btnGlow = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnCtl, curve: Curves.easeOut),
    );

    _shakeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _orbCtl.dispose();
    _particleCtl.dispose();
    _introCtl.dispose();
    _btnCtl.dispose();
    _shakeCtl.dispose();
    super.dispose();
  }

  Future<void> _saveFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await NotificationApi.saveFcmToken(fcmToken);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        NotificationApi.saveFcmToken(newToken);
      });
    } catch (_) {}
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF12202B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _login() async {
    await _btnCtl.forward();
    _btnCtl.reset();

    final username = _user.text.trim();
    final password = _pass.text;

    if (username.isEmpty || password.isEmpty) {
      _shakeCtl.forward(from: 0);
      _showSnack('Please enter both username and password');
      return;
    }

    setState(() => _loading = true);

    final res = await AuthApi.login(
      username: username,
      password: password,
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      await _saveFcmToken();
      if (!mounted) return;
      if (widget.role == 'teacher') {
        context.go(AppRoutes.teacherDash);
      } else {
        context.go(AppRoutes.studentDash);
      }
    } else {
      _shakeCtl.forward(from: 0);
      _showSnack(res['message']?.toString() ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const accent2 = Color(0xFFB388FF);
    const bg = Color(0xFF05080F);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _orbCtl,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _OrbPainter(progress: _orbCtl.value),
            ),
          ),
          AnimatedBuilder(
            animation: _particleCtl,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                  progress: _particleCtl.value, particles: _particles),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 120),
                      FadeTransition(
                        opacity: _badgeFade,
                        child: SlideTransition(
                          position: _badgeSlide,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [accent, accent2],
                                ).createShader(bounds),
                                child: const Text(
                                  'EduLearn',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ignite Your Learning Journey',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.5),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(_shake.value, 0),
                              child: child,
                            ),
                            child: _GlassCard(
                              accent: accent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _RoleBadge(role: widget.role, accent: accent),
                                  const SizedBox(height: 22),
                                  Focus(
                                    onFocusChange: (v) =>
                                        setState(() => _userFocused = v),
                                    child: _AnimatedField(
                                      focused: _userFocused,
                                      accent: accent,
                                      child: TextField(
                                        controller: _user,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 15),
                                        cursorColor: accent,
                                        decoration: InputDecoration(
                                          hintText: 'Username',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.38),
                                            fontSize: 15,
                                          ),
                                          prefixIcon: Icon(Icons.person_outline,
                                              color: _userFocused
                                                  ? accent
                                                  : Colors.white.withOpacity(0.3),
                                              size: 20),
                                          border: InputBorder.none,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Focus(
                                    onFocusChange: (v) =>
                                        setState(() => _passFocused = v),
                                    child: _AnimatedField(
                                      focused: _passFocused,
                                      accent: accent,
                                      child: TextField(
                                        controller: _pass,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 15),
                                        cursorColor: accent,
                                        obscureText: _obscure,
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.38),
                                            fontSize: 15,
                                          ),
                                          prefixIcon: Icon(Icons.lock_outline,
                                              color: _passFocused
                                                  ? accent
                                                  : Colors.white.withOpacity(0.3),
                                              size: 20),
                                          border: InputBorder.none,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                                    () => _obscure = !_obscure),
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Icon(
                                                _obscure
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                    .visibility_off_outlined,
                                                key: ValueKey(_obscure),
                                                color: accent.withOpacity(0.7),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AnimatedBuilder(
                                    animation: _btnCtl,
                                    builder: (context, _) {
                                      return Transform.scale(
                                        scale: _btnScale.value,
                                        child: Container(
                                          width: double.infinity,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accent.withOpacity(
                                                    0.25 + _btnGlow.value * 0.45),
                                                blurRadius:
                                                8 + _btnGlow.value * 24,
                                                spreadRadius: _btnGlow.value * 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _loading ? null : _login,
                                                child: Ink(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [accent, accent2],
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: AnimatedSwitcher(
                                                      duration: const Duration(
                                                          milliseconds: 220),
                                                      child: _loading
                                                          ? const SizedBox(
                                                        key: ValueKey(
                                                            'loader'),
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                          color:
                                                          Colors.black,
                                                        ),
                                                      )
                                                          : const Text(
                                                        'LOGIN',
                                                        key: ValueKey(
                                                            'label'),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight
                                                              .w900,
                                                          letterSpacing: 2,
                                                          color:
                                                          Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double baseY;
  final double speed;
  final double size;
  final double drift;

  _Particle({required int seed})
      : x = Random(seed * 17 + 3).nextDouble(),
        baseY = Random(seed * 31 + 7).nextDouble(),
        speed = 0.4 + Random(seed * 11 + 5).nextDouble() * 0.8,
        size = 1.0 + Random(seed * 5 + 2).nextDouble() * 2.2,
        drift = Random(seed * 13 + 9).nextDouble() * 2 * pi;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  _ParticlePainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final p in particles) {
      final t = (progress * p.speed + p.baseY) % 1.0;
      final y = size.height * (1 - t);
      final x = size.width * p.x + sin((progress * 2 * pi) + p.drift) * 14;
      final opacity = (sin(t * pi)).clamp(0.0, 1.0) * 0.3;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter({required this.progress});

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.55),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);

    _drawOrb(canvas,
        Offset(size.width * 0.85 + ease * 14, size.height * 0.04 - ease * 10),
        size.width * 0.70, const Color(0xFF006673), 0.98);

    _drawOrb(canvas,
        Offset(size.width * 0.04 - ease * 10, size.height * 0.43 + ease * 8),
        size.width * 0.60, const Color(0xFF5A2E8C), 0.5);

    _drawOrb(canvas,
        Offset(size.width * 0.90 + ease * 8, size.height * 0.90 + ease * 5),
        size.width * 0.54, const Color(0xFF004E5C), 0.88);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = -3; i < 7; i++) {
      final startX = size.width * 0.22 * i;
      canvas.drawLine(Offset(startX, 0),
          Offset(startX + size.height * 0.65, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.progress != progress;
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color accent;
  const _RoleBadge({required this.role, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Text(
        role == 'teacher' ? '👨‍🏫  Teacher' : '🎓  Student',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent.withOpacity(0.9),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  final bool focused;
  final Color accent;
  final Widget child;
  const _AnimatedField(
      {required this.focused, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: focused ? accent.withOpacity(0.05) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? accent.withOpacity(0.55) : Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: focused
            ? [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 14)]
            : [],
      ),
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  const _GlassCard({required this.child, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.06),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
