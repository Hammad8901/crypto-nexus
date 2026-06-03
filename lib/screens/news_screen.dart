import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/sentiment_gauge.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allNews = mockCryptos.expand((a) => a.recentNews).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final overallScore = allNews.isEmpty
        ? 0.0
        : allNews.fold(0.0, (s, n) => s + n.sentimentScore) / allNews.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'News & Sentiment',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time analysis from Reuters, Bloomberg, CoinDesk, The Block & more',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Overall sentiment banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _OverallSentimentBanner(score: overallScore, count: allNews.length),
            ),
          ),

          // Source badges
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                children: const [
                  _SourceBadge('Reuters', Color(0xFFFF6B00)),
                  _SourceBadge('Bloomberg', Color(0xFF0066FF)),
                  _SourceBadge('CoinDesk', Color(0xFF00C3A5)),
                  _SourceBadge('The Block', Color(0xFF7C3AED)),
                  _SourceBadge('Decrypt', Color(0xFFF7931A)),
                  _SourceBadge('CoinTelegraph', Color(0xFF00A8E0)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Per-crypto sentiment
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: const Text(
                'SENTIMENT BY ASSET',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                itemCount: mockCryptos.length,
                itemBuilder: (ctx, i) {
                  final a = mockCryptos[i];
                  return _AssetSentimentChip(
                    symbol: a.symbol,
                    score: a.sentiment.score,
                    label: a.sentiment.label,
                    index: i,
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'LATEST NEWS',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NewsCard(news: allNews[i], index: i),
              ),
              childCount: allNews.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _OverallSentimentBanner extends StatelessWidget {
  final double score;
  final int count;
  const _OverallSentimentBanner({required this.score, required this.count});

  Color get _bgColor => score > 0.3
      ? AppColors.positiveDim
      : score < -0.3
          ? AppColors.negativeDim
          : AppColors.secondaryDim;

  Color get _textColor => score > 0.3
      ? AppColors.positive
      : score < -0.3
          ? AppColors.negative
          : AppColors.neutral;

  String get _emoji => score > 0.5
      ? '🚀'
      : score > 0.2
          ? '📈'
          : score < -0.5
              ? '🔴'
              : score < -0.2
                  ? '📉'
                  : '⚖️';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Sentiment: ${score >= 0 ? '+' : ''}${score.toStringAsFixed(2)}',
                  style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Based on $count articles from ${mockCryptos.length} tracked assets',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }
}

class _SourceBadge extends StatelessWidget {
  final String name;
  final Color color;
  const _SourceBadge(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _AssetSentimentChip extends StatelessWidget {
  final String symbol, label;
  final double score;
  final int index;
  const _AssetSentimentChip({
    required this.symbol,
    required this.score,
    required this.label,
    required this.index,
  });

  static const Map<String, Color> _coinColors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'AVAX': Color(0xFFE84142),
  };

  @override
  Widget build(BuildContext context) {
    final coinColor = _coinColors[symbol] ?? AppColors.primary;
    final sentColor = score > 0 ? AppColors.positive : AppColors.negative;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sentColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: sentColor.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 3, height: 32, decoration: BoxDecoration(color: coinColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(symbol, style: TextStyle(color: coinColor, fontSize: 11, fontWeight: FontWeight.w800)),
              Text(
                '${score >= 0 ? '+' : ''}${score.toStringAsFixed(2)}',
                style: TextStyle(color: sentColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
