import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;
  const AnimatedMeshBackground({super.key, required this.child});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _gradientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient orbs
        AnimatedBuilder(
          animation: _gradientCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GradientOrbPainter(t: _gradientCtrl.value),
          ),
        ),
        // Moving particles
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ParticlePainter(t: _particleCtrl.value),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _GradientOrbPainter extends CustomPainter {
  final double t;
  _GradientOrbPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Orb 1 — cyan top-left
    final x1 = cx * (0.3 + 0.2 * sin(t * pi * 2));
    final y1 = cy * (0.2 + 0.15 * cos(t * pi * 2));
    canvas.drawCircle(
      Offset(x1, y1),
      size.width * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x1, y1), radius: size.width * 0.35)),
    );

    // Orb 2 — purple bottom-right
    final x2 = cx * (1.4 + 0.2 * cos(t * pi * 2 + 1));
    final y2 = cy * (1.5 + 0.15 * sin(t * pi * 2 + 1));
    canvas.drawCircle(
      Offset(x2, y2),
      size.width * 0.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.07),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x2, y2), radius: size.width * 0.4)),
    );

    // Orb 3 — orange mid
    final x3 = cx * (0.9 + 0.3 * sin(t * pi * 2 + 2));
    final y3 = cy * (0.8 + 0.2 * cos(t * pi * 2 + 2));
    canvas.drawCircle(
      Offset(x3, y3),
      size.width * 0.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x3, y3), radius: size.width * 0.25)),
    );
  }

  @override
  bool shouldRepaint(_GradientOrbPainter old) => old.t != t;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _particles = List.generate(50, (_) => [
    _rng.nextDouble(), // x frac
    _rng.nextDouble(), // y frac
    _rng.nextDouble(), // speed
    _rng.nextDouble(), // size
    _rng.nextDouble(), // phase
  ]);

  _ParticlePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = (p[0] + t * p[2] * 0.1) % 1.0 * size.width;
      final y = (p[1] + t * p[2] * 0.05 + sin(t * 2 * pi + p[4] * 2 * pi) * 0.02) % 1.0 * size.height;
      final opacity = 0.1 + 0.2 * sin(t * 2 * pi + p[4] * 2 * pi).abs();
      final dotSize = 0.8 + p[3] * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        dotSize,
        Paint()..color = const Color(0xFF00D4FF).withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

/// Tilt card — gives 3D perspective effect on hover/drag
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final BorderRadius borderRadius;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 6.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, BoxConstraints c) {
    setState(() {
      _tiltY = ((d.localPosition.dx / c.maxWidth) - 0.5) * widget.maxTilt * 2;
      _tiltX = -((d.localPosition.dy / c.maxHeight) - 0.5) * widget.maxTilt * 2;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d, constraints),
        onPanEnd: _onPanEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX * pi / 180)
            ..rotateY(_tiltY * pi / 180),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      );
    });
  }
}

/// Animated number that smoothly counts up/down when value changes
class AnimatedNumber extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: widget.value, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value;
      _anim = Tween<double>(begin: _from, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(widget.formatter(_anim.value), style: widget.style),
    );
  }
}
