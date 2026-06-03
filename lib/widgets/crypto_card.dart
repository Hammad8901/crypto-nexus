import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/crypto_asset.dart';
import '../theme/app_theme.dart';
import 'animated_background.dart';
import 'wow_card.dart';

class CryptoPortfolioCard extends StatelessWidget {
  final CryptoAsset asset;
  final int index;
  final VoidCallback onTap;

  const CryptoPortfolioCard({
    super.key,
    required this.asset,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = asset.isProfit ? AppColors.positive : AppColors.negative;
    final fmt = NumberFormat('\$#,##0.00');
    final fmtSmall = NumberFormat('\$#,##0.##');

    return CandleRevealCard(
      accentColor: priceColor,
      delayMs: 80 * index,
      child: GestureDetector(
        onTap: onTap,
        child: HeroCryptoCard(
          heroTag: 'crypto_hero_${asset.id}',
          child: TiltCard(
            borderRadius: BorderRadius.circular(20),
            child: WowCard(
              glowColor: priceColor,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      _GlowAccent(color: priceColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CoinBadge(symbol: asset.symbol),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${asset.holdings} ${asset.symbol}',
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SignalBadge(signal: asset.ensemble.signal),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(asset.totalValue),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  asset.isProfit
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  color: priceColor,
                                  size: 16,
                                ),
                                Text(
                                  '${asset.pnlPercent.abs().toStringAsFixed(2)}%  '
                                  '${asset.isProfit ? '+' : ''}${fmtSmall.format(asset.pnl)}',
                                  style: TextStyle(
                                    color: priceColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _SparklineWidget(data: asset.sparkline, isUp: asset.isProfit)),
                        const SizedBox(width: 14),
                        _SentimentMini(score: asset.sentiment.score),
                        const SizedBox(width: 14),
                        _AiConfidence(confidence: asset.ensemble.confidence),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          fmtSmall.format(asset.price),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: asset.changePercent24h >= 0
                                ? AppColors.positiveDim
                                : AppColors.negativeDim,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${asset.changePercent24h >= 0 ? '+' : ''}${asset.changePercent24h.toStringAsFixed(2)}% 24h',
                            style: TextStyle(
                              color: asset.changePercent24h >= 0
                                  ? AppColors.positive
                                  : AppColors.negative,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Avg: ${fmtSmall.format(asset.avgBuyPrice)}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],       // Row children
                    ),         // Row
                  ],           // Column children
                ),             // Column
              ),               // Padding
            ],                 // Stack children
          ),                   // Stack
        ),                     // ClipRRect
      ),                       // Container
    ),                         // WowCard
  ),                           // TiltCard
),                             // HeroCryptoCard
      ),                       // GestureDetector
    );                         // CandleRevealCard
  }
}

class _GlowAccent extends StatelessWidget {
  final Color color;
  const _GlowAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -30,
      top: -30,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.05),
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final String symbol;
  const _CoinBadge({required this.symbol});

  static const Map<String, Color> _colors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'AVAX': Color(0xFFE84142),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[symbol] ?? AppColors.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, 1),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  final String signal;
  const _SignalBadge({required this.signal});

  Color _color() {
    if (signal.contains('STRONG BUY')) return AppColors.positive;
    if (signal.contains('BUY')) return AppColors.positive.withOpacity(0.8);
    if (signal.contains('SELL')) return AppColors.negative;
    return AppColors.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color().withOpacity(0.3)),
      ),
      child: Text(
        signal,
        style: TextStyle(
          color: _color(),
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SparklineWidget extends StatelessWidget {
  final List<double> data;
  final bool isUp;
  const _SparklineWidget({required this.data, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: CustomPaint(
        painter: _SparkPainter(data: data, isUp: isUp),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final bool isUp;
  _SparkPainter({required this.data, required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range == 0) return;

    final color = isUp ? AppColors.positive : AppColors.negative;
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * (1 - (data[i] - min) / range);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.data != data;
}

class _SentimentMini extends StatelessWidget {
  final double score;
  const _SentimentMini({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0 ? AppColors.positive : AppColors.negative;
    return Column(
      children: [
        Text(
          'SENTIMENT',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 8, letterSpacing: 0.4),
        ),
        const SizedBox(height: 2),
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _AiConfidence extends StatelessWidget {
  final double confidence;
  const _AiConfidence({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'AI CONF.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 8, letterSpacing: 0.4),
        ),
        const SizedBox(height: 2),
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
