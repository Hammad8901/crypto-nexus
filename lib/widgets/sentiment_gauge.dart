import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/crypto_asset.dart';
import '../theme/app_theme.dart';

class SentimentGauge extends StatelessWidget {
  final SentimentData sentiment;

  const SentimentGauge({super.key, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'NEWS SENTIMENT',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              _SentimentLabel(label: sentiment.label, score: sentiment.score),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 140,
              height: 80,
              child: CustomPaint(
                painter: _GaugePainter(score: sentiment.score),
                child: Padding(
                  padding: const EdgeInsets.only(top: 38),
                  child: Column(
                    children: [
                      Text(
                        sentiment.score >= 0 ? '+${sentiment.score.toStringAsFixed(2)}' : sentiment.score.toStringAsFixed(2),
                        style: TextStyle(
                          color: sentiment.score > 0 ? AppColors.positive : AppColors.negative,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _countChip('Bullish', sentiment.positive, AppColors.positive),
              _countChip('Neutral', sentiment.neutral, AppColors.neutral),
              _countChip('Bearish', sentiment.negative, AppColors.negative),
            ],
          ),
          const SizedBox(height: 12),
          _DistributionBar(
            positive: sentiment.positive,
            neutral: sentiment.neutral,
            negative: sentiment.negative,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _countChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

class _SentimentLabel extends StatelessWidget {
  final String label;
  final double score;
  const _SentimentLabel({required this.label, required this.score});

  Color get _color {
    if (score > 0.5) return AppColors.positive;
    if (score > 0) return AppColors.positive.withOpacity(0.7);
    if (score > -0.5) return AppColors.negative.withOpacity(0.7);
    return AppColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background arc
    canvas.drawArc(
      rect, pi, pi, false,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Colored fill
    final clampedScore = score.clamp(-1.0, 1.0);
    final sweepAngle = (clampedScore + 1) / 2 * pi;
    final Color arcColor;
    if (clampedScore > 0.3) {
      arcColor = AppColors.positive;
    } else if (clampedScore < -0.3) {
      arcColor = AppColors.negative;
    } else {
      arcColor = AppColors.neutral;
    }

    canvas.drawArc(
      rect, pi, sweepAngle, false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Needle
    final angle = pi + sweepAngle;
    final needleEnd = Offset(
      cx + (radius - 8) * cos(angle),
      cy + (radius - 8) * sin(angle),
    );
    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = AppColors.textPrimary);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

class _DistributionBar extends StatelessWidget {
  final int positive, neutral, negative;
  const _DistributionBar({
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    final total = positive + neutral + negative;
    if (total == 0) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          Expanded(flex: positive, child: Container(height: 4, color: AppColors.positive)),
          Expanded(flex: neutral, child: Container(height: 4, color: AppColors.neutral)),
          Expanded(flex: negative, child: Container(height: 4, color: AppColors.negative)),
        ],
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem news;
  final int index;

  const NewsCard({super.key, required this.news, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPos = news.isPositive;
    final isNeg = news.isNegative;
    final color = isPos ? AppColors.positive : isNeg ? AppColors.negative : AppColors.neutral;
    final timeAgo = _timeAgo(news.publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.headline,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      news.source,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text('·', style: const TextStyle(color: AppColors.textTertiary)),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${news.sentimentScore >= 0 ? '+' : ''}${news.sentimentScore.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
