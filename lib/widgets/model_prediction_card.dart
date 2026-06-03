import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/candle_data.dart';
import '../models/crypto_asset.dart';
import '../theme/app_theme.dart';

class ModelPredictionCard extends StatelessWidget {
  final ModelPrediction prediction;
  final int index;

  const ModelPredictionCard({
    super.key,
    required this.prediction,
    required this.index,
  });

  static const Map<String, Color> _modelColors = {
    'LSTM': AppColors.lstm,
    'GRU': AppColors.gru,
    'GAN': AppColors.gan,
    'Hybrid': AppColors.custom,
  };

  static const Map<String, String> _descriptions = {
    'LSTM': 'Long Short-Term Memory — sequential pattern recognition',
    'GRU': 'Gated Recurrent Unit — faster training, strong recall',
    'GAN': 'Generative Adversarial — synthetic scenario modeling',
    'Hybrid': 'Custom CNN+LSTM — multi-timeframe fusion',
  };

  @override
  Widget build(BuildContext context) {
    final color = _modelColors[prediction.modelName] ?? AppColors.primary;
    final isBull = prediction.isBullish;
    final signalColor = isBull ? AppColors.positive : AppColors.negative;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  prediction.modelName,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: signalColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBull ? '▲ BULLISH' : '▼ BEARISH',
                  style: TextStyle(
                    color: signalColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _descriptions[prediction.modelName] ?? '',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricColumn('Bullish Prob.', '${(prediction.bullishProb * 100).toStringAsFixed(1)}%', isBull ? AppColors.positive : AppColors.negative),
              _metricColumn('Confidence', '${(prediction.confidence * 100).toStringAsFixed(1)}%', AppColors.primary),
              _metricColumn('Target Price', '\$${_formatPrice(prediction.predictedPrice)}', AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prediction.bullishProb,
              backgroundColor: AppColors.negativeDim,
              valueColor: AlwaysStoppedAnimation(
                isBull ? AppColors.positive : AppColors.negative,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(2)}k';
    return price.toStringAsFixed(2);
  }
}

class EnsembleResultCard extends StatelessWidget {
  final EnsembleResult result;
  final double currentPrice;

  const EnsembleResultCard({
    super.key,
    required this.result,
    required this.currentPrice,
  });

  Color get _signalColor {
    if (result.signal.contains('STRONG BUY')) return AppColors.positive;
    if (result.signal.contains('BUY')) return AppColors.positive.withOpacity(0.8);
    if (result.signal.contains('STRONG SELL')) return AppColors.negative;
    if (result.signal.contains('SELL')) return AppColors.negative.withOpacity(0.8);
    return AppColors.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _signalColor.withOpacity(0.12),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _signalColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ENSEMBLE VERDICT',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _signalColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.signal,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Price', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_formatPrice(result.predictedPrice)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${result.priceChangePercent >= 0 ? '+' : ''}${result.priceChangePercent.toStringAsFixed(2)}% expected',
                      style: TextStyle(
                        color: result.priceChangePercent >= 0 ? AppColors.positive : AppColors.negative,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _CircularConfidence(confidence: result.confidence, color: _signalColor),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Model Weight Distribution',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          _ModelWeightBar(weights: result.modelWeights),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05, end: 0);
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(2)}k';
    return price.toStringAsFixed(2);
  }
}

class _CircularConfidence extends StatelessWidget {
  final double confidence;
  final Color color;
  const _CircularConfidence({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: confidence,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 5,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'CONF',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 7, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelWeightBar extends StatelessWidget {
  final Map<String, double> weights;
  const _ModelWeightBar({required this.weights});

  static const Map<String, Color> _colors = {
    'LSTM': AppColors.lstm,
    'GRU': AppColors.gru,
    'GAN': AppColors.gan,
    'Hybrid': AppColors.custom,
  };

  @override
  Widget build(BuildContext context) {
    final entries = weights.entries.toList();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: entries.map((e) {
              final color = _colors[e.key] ?? AppColors.primary;
              return Expanded(
                flex: (e.value * 100).round(),
                child: Container(height: 6, color: color),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: entries.map((e) {
            final color = _colors[e.key] ?? AppColors.primary;
            return Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Text(
                    '${e.key} ${(e.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
