import 'package:equatable/equatable.dart';

class SentimentData extends Equatable {
  final double score;
  final int positive;
  final int negative;
  final int neutral;
  final String label;

  const SentimentData({
    required this.score,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.label,
  });

  @override
  List<Object?> get props => [score, positive, negative, neutral, label];
}

class NewsItem extends Equatable {
  final String id;
  final String headline;
  final String source;
  final String url;
  final double sentimentScore;
  final DateTime publishedAt;
  final String symbol;

  const NewsItem({
    required this.id,
    required this.headline,
    required this.source,
    required this.url,
    required this.sentimentScore,
    required this.publishedAt,
    required this.symbol,
  });

  bool get isPositive => sentimentScore > 0.2;
  bool get isNegative => sentimentScore < -0.2;

  @override
  List<Object?> get props => [id, headline, source, sentimentScore, publishedAt];
}

class EnsembleResult extends Equatable {
  final double bullishProbability;
  final double predictedPrice;
  final double priceChangePercent;
  final String signal;
  final double confidence;
  final Map<String, double> modelWeights;

  const EnsembleResult({
    required this.bullishProbability,
    required this.predictedPrice,
    required this.priceChangePercent,
    required this.signal,
    required this.confidence,
    required this.modelWeights,
  });

  @override
  List<Object?> get props => [bullishProbability, predictedPrice, signal];
}

class CryptoAsset extends Equatable {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double marketCap;
  final double volume24h;
  final double holdings;
  final double avgBuyPrice;
  final List<double> sparkline;
  final SentimentData sentiment;
  final EnsembleResult ensemble;
  final List<NewsItem> recentNews;

  const CryptoAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.marketCap,
    required this.volume24h,
    required this.holdings,
    required this.avgBuyPrice,
    required this.sparkline,
    required this.sentiment,
    required this.ensemble,
    required this.recentNews,
  });

  double get totalValue => price * holdings;
  double get pnl => (price - avgBuyPrice) * holdings;
  double get pnlPercent => ((price - avgBuyPrice) / avgBuyPrice) * 100;
  bool get isProfit => pnl >= 0;

  @override
  List<Object?> get props => [id, symbol, price];
}
