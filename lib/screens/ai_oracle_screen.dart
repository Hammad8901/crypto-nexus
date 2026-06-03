import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/model_prediction_card.dart';

class AiOracleScreen extends StatelessWidget {
  const AiOracleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assets = mockCryptos;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Oracle',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.positiveDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: AppColors.positive, size: 6),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: AppColors.positive, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ensemble of LSTM · GRU · GAN · Hybrid models with XAI explainability',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Model architecture cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: const Text(
                'MODEL ARCHITECTURE',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                children: [
                  _ModelArchCard(
                    name: 'LSTM',
                    color: AppColors.lstm,
                    accuracy: 0.847,
                    description: '128 units × 3 layers\nDropout 0.2\nSequence len: 60',
                    index: 0,
                  ),
                  _ModelArchCard(
                    name: 'GRU',
                    color: AppColors.gru,
                    accuracy: 0.831,
                    description: '256 units × 2 layers\nBidirectional\nSequence len: 48',
                    index: 1,
                  ),
                  _ModelArchCard(
                    name: 'GAN',
                    color: AppColors.gan,
                    accuracy: 0.819,
                    description: 'Generator + Discriminator\nMonte Carlo scenarios\nBootstrap ensemble',
                    index: 2,
                  ),
                  _ModelArchCard(
                    name: 'Hybrid',
                    color: AppColors.custom,
                    accuracy: 0.863,
                    description: 'CNN feature extractor\n+ LSTM temporal\nMulti-timeframe',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),

          // Per-asset verdicts
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: const Text(
                'ENSEMBLE VERDICTS',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SmallCoinChip(symbol: assets[i].symbol),
                        const SizedBox(width: 8),
                        Text(assets[i].name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    EnsembleResultCard(
                      result: assets[i].ensemble,
                      currentPrice: assets[i].price,
                    ),
                  ],
                ),
              ),
              childCount: assets.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ModelArchCard extends StatelessWidget {
  final String name, description;
  final Color color;
  final double accuracy;
  final int index;

  const _ModelArchCard({
    required this.name,
    required this.description,
    required this.color,
    required this.accuracy,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${(accuracy * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const Text('accuracy', style: TextStyle(color: AppColors.textTertiary, fontSize: 8)),
          const Spacer(),
          Text(description, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9, height: 1.5)),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

class _SmallCoinChip extends StatelessWidget {
  final String symbol;
  const _SmallCoinChip({required this.symbol});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(symbol, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
