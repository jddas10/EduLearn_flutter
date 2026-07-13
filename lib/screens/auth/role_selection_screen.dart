import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtl;
  late final AnimationController _introCtl;
  late final AnimationController _particleCtl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _card1Fade;
  late final Animation<Offset> _card1Slide;
  late final Animation<double> _card2Fade;
  late final Animation<Offset> _card2Slide;

  final List<_Particle> _particles = List.generate(
    28,
        (i) => _Particle(seed: i),
  );

  @override
  void initState() {
    super.initState();

    _orbCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _particleCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _introCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _titleFade = CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _card1Fade = CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    ));

    _card2Fade = CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _orbCtl.dispose();
    _introCtl.dispose();
    _particleCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const accent2 = Color(0xFFB388FF);
    const bgColor = Color(0xFF05080F);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
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
                progress: _particleCtl.value,
                particles: _particles,
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: _GridPainter(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [accent, accent2],
                            ).createShader(bounds),
                            child: const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Choose how you want to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.45),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  FadeTransition(
                    opacity: _card1Fade,
                    child: SlideTransition(
                      position: _card1Slide,
                      child: _RoleCard(
                        label: 'Student',
                        subtitle: 'Access your courses & progress',
                        icon: Icons.school_rounded,
                        accent: accent,
                        onTap: () =>
                            context.go('${AppRoutes.login}?role=student'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _card2Fade,
                    child: SlideTransition(
                      position: _card2Slide,
                      child: _RoleCard(
                        label: 'Teacher',
                        subtitle: 'Manage classes & students',
                        icon: Icons.workspace_premium_rounded,
                        accent: accent2,
                        onTap: () =>
                            context.go('${AppRoutes.login}?role=teacher'),
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
      final x = size.width * p.x +
          sin((progress * 2 * pi) + p.drift) * 14;
      final opacity = (sin(t * pi)).clamp(0.0, 1.0) * 0.35;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
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
          color.withOpacity(opacity * 0.5),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);

    _drawOrb(
      canvas,
      Offset(size.width * 0.85 + ease * 18, size.height * 0.05 - ease * 14),
      size.width * 0.72,
      const Color(0xFF00596B),
      0.95,
    );
    _drawOrb(
      canvas,
      Offset(size.width * 0.02 - ease * 12, size.height * 0.45 + ease * 10),
      size.width * 0.62,
      const Color(0xFF5A2E8C),
      0.55,
    );
    _drawOrb(
      canvas,
      Offset(size.width * 0.92 + ease * 10, size.height * 0.92 + ease * 6),
      size.width * 0.56,
      const Color(0xFF004E5C),
      0.85,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.progress != progress;
}

class _RoleCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtl;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _pressCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => _pressCtl.forward(),
        onTapCancel: () => _pressCtl.reverse(),
        onTapUp: (_) {
          _pressCtl.reverse();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pressCtl,
          builder: (context, child) {
            final scale = 1.0 - (_pressCtl.value * 0.035);
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accent.withOpacity(_hovering ? 0.22 : 0.14),
                  widget.accent.withOpacity(_hovering ? 0.08 : 0.04),
                ],
              ),
              border: Border.all(
                color: widget.accent.withOpacity(_hovering ? 0.55 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(_hovering ? 0.28 : 0.1),
                  blurRadius: _hovering ? 28 : 14,
                  spreadRadius: _hovering ? 1 : 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accent.withOpacity(0.16),
                    border: Border.all(
                        color: widget.accent.withOpacity(0.4), width: 1),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _hovering ? 0.0 : -0.02,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.accent,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}