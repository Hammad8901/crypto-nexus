import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A card that pulses with a colour-matched glow border, runs a shimmer sweep,
/// and fires an explosive scale+fade entrance animation.
class WowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final BorderRadius borderRadius;
  final bool enableShimmer;
  final bool enableGlow;

  const WowCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.enableShimmer = true,
    this.enableGlow = true,
  });

  @override
  State<WowCard> createState() => _WowCardState();
}

class _WowCardState extends State<WowCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        final t = _shimmerCtrl.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: widget.enableGlow
                ? [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.08 + 0.06 * sin(t * 2 * pi)),
                      blurRadius: 24 + 8 * sin(t * 2 * pi),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.04),
                      blurRadius: 48,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              children: [
                child!,
                if (widget.enableShimmer)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final shimmerX = -1.0 + 3.0 * t;
                          return LinearGradient(
                            begin: Alignment(shimmerX - 0.8, -0.5),
                            end: Alignment(shimmerX + 0.8, 0.5),
                            colors: [
                              Colors.transparent,
                              widget.glowColor.withOpacity(0.06),
                              widget.glowColor.withOpacity(0.12),
                              widget.glowColor.withOpacity(0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ).createShader(bounds);
                        },
                        child: Container(
                          color: Colors.white.withOpacity(0.001),
                        ),
                      ),
                    ),
                  ),
                // Glowing top border line
                if (widget.enableGlow)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            widget.glowColor.withOpacity(0.4 + 0.2 * sin(t * 2 * pi)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Hero-aware crypto card wrapper.
/// Morph tag: 'crypto_${asset.id}'
class HeroCryptoCard extends StatelessWidget {
  final String heroTag;
  final Widget child;

  const HeroCryptoCard({super.key, required this.heroTag, required this.child});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (_, anim, dir, fromCtx, toCtx) {
        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: anim.value.clamp(0.0, 1.0),
              child: FractionalTranslation(
                translation: Offset(0, (1 - anim.value) * 0.05),
                child: dir == HeroFlightDirection.push ? toCtx.widget : fromCtx.widget,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Candle-to-card entrance: candles draw from bottom, then expand into the card.
class CandleRevealCard extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Color accentColor;

  const CandleRevealCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.delayMs = 0,
  });

  @override
  State<CandleRevealCard> createState() => _CandleRevealCardState();
}

class _CandleRevealCardState extends State<CandleRevealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _candleGrow;
  late Animation<double> _cardReveal;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _candleGrow = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _cardReveal = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutExpo),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Stack(
          children: [
            // Phase 1: mini candle sticks rising up
            if (_ctrl.value < 0.5)
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - _cardReveal.value).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _MiniCandlesPainter(
                      progress: _candleGrow.value,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),

            // Phase 2: card reveals with clip
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _cardReveal.value,
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * _cardReveal.value,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _MiniCandlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final _rng = Random(7);
  static final _candles = List.generate(
    12,
    (_) => [0.3 + _rng.nextDouble() * 0.7, _rng.nextDouble() > 0.4 ? 1.0 : -1.0],
  );

  _MiniCandlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final candleW = size.width / _candles.length;
    final maxH = size.height * 0.6;

    for (int i = 0; i < _candles.length; i++) {
      final relH = _candles[i][0];
      final isBull = _candles[i][1] > 0;
      final h = maxH * relH * progress;
      final x = i * candleW + candleW / 2;
      final y = size.height - h;
      final c = isBull ? color : color.withOpacity(0.4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - candleW * 0.25, y, candleW * 0.5, h),
          const Radius.circular(2),
        ),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniCandlesPainter old) => old.progress != progress;
}

/// Big animated metric — number counts up with glow explosion on mount.
class ExplosiveMetric extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final double fontSize;
  final int delayMs;

  const ExplosiveMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.fontSize = 36,
    this.delayMs = 0,
  });

  @override
  State<ExplosiveMetric> createState() => _ExplosiveMetricState();
}

class _ExplosiveMetricState extends State<ExplosiveMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _slide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Transform.scale(
          scale: _scale.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Stack(
                children: [
                  // Glow burst behind text
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(_glow.value * 0.3),
                              blurRadius: 24 * _glow.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      shadows: [
                        Shadow(
                          color: widget.color.withOpacity(_glow.value * 0.6),
                          blurRadius: 16 * _glow.value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
