import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'web_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ResponsiveLayout(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background grid
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter(),
          ),

          // Orbiting particles
          AnimatedBuilder(
            animation: _orbitController,
            builder: (_, __) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _OrbitPainter(progress: _orbitController.value),
              );
            },
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing logo orb
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Container(
                    width: 100 + _pulseController.value * 6,
                    height: 100 + _pulseController.value * 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.9),
                          AppColors.secondary.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4 + _pulseController.value * 0.2),
                          blurRadius: 40 + _pulseController.value * 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: const Center(
                    child: Text(
                      'CN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'CRYPTO NEXUS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 700.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),
                const Text(
                  'AI-POWERED PORTFOLIO INTELLIGENCE',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 700.ms),

                const SizedBox(height: 48),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modelChip('LSTM').animate(delay: 900.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                    _modelChip('GRU').animate(delay: 1050.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                    _modelChip('GAN').animate(delay: 1200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                    _modelChip('XAI').animate(delay: 1350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelChip(String label) {
    final colors = {
      'LSTM': AppColors.lstm,
      'GRU': AppColors.gru,
      'GAN': AppColors.gan,
      'XAI': AppColors.ensemble,
    };
    final color = colors[label] ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final orbits = [
      (160.0, AppColors.primary, 4.0, 0.0),
      (220.0, AppColors.secondary, 6.0, 0.3),
      (280.0, AppColors.accent, 5.0, 0.6),
    ];

    for (final (r, color, dotSize, offset) in orbits) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      final angle = 2 * 3.14159 * ((progress + offset) % 1.0);
      final dotX = cx + r * _cos(angle);
      final dotY = cy + r * _sin(angle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        dotSize,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(Offset(dotX, dotY), dotSize * 0.5, Paint()..color = color);
    }
  }

  double _cos(double a) => (a % (2 * 3.14159) < 3.14159)
      ? 1 - 2 * (a % 3.14159) / 3.14159
      : -1 + 2 * ((a - 3.14159) % 3.14159) / 3.14159;

  double _sin(double a) => _cos(a - 3.14159 / 2);

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}
