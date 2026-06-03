import 'dart:math';
import '../models/crypto_asset.dart';
import '../models/candle_data.dart';

final _rng = Random(42);

double _rnd(double min, double max) => min + _rng.nextDouble() * (max - min);

List<CandleData> generateCandles(double basePrice, int count) {
  final candles = <CandleData>[];
  double price = basePrice;
  final now = DateTime.now();

  final newsEventDefs = [
    ('BlackRock Bitcoin ETF sees record \$500M inflow', 'Reuters', 0.92),
    ('Fed signals potential rate cut — risk assets rally', 'Bloomberg', 0.78),
    ('Major exchange reports security breach — markets drop', 'CoinDesk', -0.85),
    ('Ethereum ETF approval expected within weeks', 'The Block', 0.88),
  ];

  for (int i = count - 1; i >= 0; i--) {
    final time = now.subtract(Duration(hours: i * 4));
    final volatility = price * 0.02;
    final open = price;
    final change = (_rng.nextDouble() - 0.48) * volatility * 2;
    final close = open + change;
    final high = max(open, close) + _rng.nextDouble() * volatility;
    final low = min(open, close) - _rng.nextDouble() * volatility;
    final volume = _rnd(1000, 8000);

    NewsEvent? event;
    XaiExplanation? xai;
    List<ModelPrediction>? preds;

    final hasEvent = _rng.nextDouble() > 0.85;
    if (hasEvent) {
      final def = newsEventDefs[_rng.nextInt(newsEventDefs.length)];
      event = NewsEvent(
        headline: def.$1,
        source: def.$2,
        sentimentScore: def.$3,
        time: time,
      );

      xai = XaiExplanation(
        summary: change > 0
            ? 'Bullish momentum driven by news sentiment and volume spike'
            : 'Bearish pressure from market fear and selling volume',
        features: [
          XaiFeature(name: 'News Sentiment', impact: 3.1, isPositive: change > 0),
          XaiFeature(name: 'RSI Signal', impact: 2.3, isPositive: change > 0),
          XaiFeature(name: 'Volume Spike', impact: 1.8, isPositive: change > 0),
          XaiFeature(name: 'BTC Dominance', impact: 0.9, isPositive: change > 0),
          XaiFeature(name: 'Market Cap Flow', impact: 0.6, isPositive: _rng.nextBool()),
        ],
      );

      final bullish = change > 0;
      preds = [
        ModelPrediction(
          modelName: 'LSTM',
          bullishProb: bullish ? _rnd(0.68, 0.92) : _rnd(0.08, 0.38),
          predictedPrice: close * (1 + _rnd(-0.01, 0.015)),
          confidence: _rnd(0.72, 0.91),
        ),
        ModelPrediction(
          modelName: 'GRU',
          bullishProb: bullish ? _rnd(0.62, 0.88) : _rnd(0.12, 0.42),
          predictedPrice: close * (1 + _rnd(-0.01, 0.015)),
          confidence: _rnd(0.68, 0.88),
        ),
        ModelPrediction(
          modelName: 'GAN',
          bullishProb: bullish ? _rnd(0.70, 0.95) : _rnd(0.05, 0.35),
          predictedPrice: close * (1 + _rnd(-0.012, 0.018)),
          confidence: _rnd(0.65, 0.85),
        ),
        ModelPrediction(
          modelName: 'Hybrid',
          bullishProb: bullish ? _rnd(0.65, 0.90) : _rnd(0.10, 0.40),
          predictedPrice: close * (1 + _rnd(-0.008, 0.012)),
          confidence: _rnd(0.75, 0.93),
        ),
      ];
    }

    candles.add(CandleData(
      time: time,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
      predictions: preds,
      xai: xai,
      triggeringEvent: event,
    ));

    price = close;
  }

  return candles;
}

List<double> _sparkline(double base, int points) {
  double p = base;
  return List.generate(points, (_) {
    p += (_rng.nextDouble() - 0.48) * p * 0.03;
    return p;
  });
}

final mockCryptos = [
  CryptoAsset(
    id: 'bitcoin',
    symbol: 'BTC',
    name: 'Bitcoin',
    price: 67420.50,
    change24h: 1234.80,
    changePercent24h: 1.87,
    marketCap: 1324000000000,
    volume24h: 28400000000,
    holdings: 0.42,
    avgBuyPrice: 52000,
    sparkline: _sparkline(67420, 24),
    sentiment: const SentimentData(
      score: 0.74,
      positive: 1842,
      negative: 312,
      neutral: 543,
      label: 'Very Bullish',
    ),
    ensemble: const EnsembleResult(
      bullishProbability: 0.81,
      predictedPrice: 71200,
      priceChangePercent: 5.6,
      signal: 'STRONG BUY',
      confidence: 0.87,
      modelWeights: {'LSTM': 0.30, 'GRU': 0.25, 'GAN': 0.20, 'Hybrid': 0.25},
    ),
    recentNews: [
      NewsItem(
        id: 'n1',
        headline: 'BlackRock Bitcoin ETF sees record \$500M single-day inflow',
        source: 'Reuters',
        url: '',
        sentimentScore: 0.92,
        publishedAt: DateTime(2026, 6, 2, 9, 0),
        symbol: 'BTC',
      ),
      NewsItem(
        id: 'n2',
        headline: 'MicroStrategy acquires additional 11,000 BTC worth \$750M',
        source: 'Bloomberg',
        url: '',
        sentimentScore: 0.84,
        publishedAt: DateTime(2026, 6, 2, 6, 0),
        symbol: 'BTC',
      ),
      NewsItem(
        id: 'n3',
        headline: 'Bitcoin mining difficulty hits all-time high after halving',
        source: 'CoinDesk',
        url: '',
        sentimentScore: 0.31,
        publishedAt: DateTime(2026, 6, 2, 2, 0),
        symbol: 'BTC',
      ),
    ],
  ),
  CryptoAsset(
    id: 'ethereum',
    symbol: 'ETH',
    name: 'Ethereum',
    price: 3812.30,
    change24h: -48.20,
    changePercent24h: -1.25,
    marketCap: 458000000000,
    volume24h: 14200000000,
    holdings: 3.5,
    avgBuyPrice: 2800,
    sparkline: _sparkline(3812, 24),
    sentiment: const SentimentData(
      score: 0.42,
      positive: 923,
      negative: 487,
      neutral: 612,
      label: 'Slightly Bullish',
    ),
    ensemble: const EnsembleResult(
      bullishProbability: 0.58,
      predictedPrice: 3950,
      priceChangePercent: 3.6,
      signal: 'BUY',
      confidence: 0.72,
      modelWeights: {'LSTM': 0.28, 'GRU': 0.30, 'GAN': 0.22, 'Hybrid': 0.20},
    ),
    recentNews: [
      NewsItem(
        id: 'n4',
        headline: 'Ethereum spot ETF approval expected Q3 — analyst report',
        source: 'The Block',
        url: '',
        sentimentScore: 0.88,
        publishedAt: DateTime(2026, 6, 2, 10, 0),
        symbol: 'ETH',
      ),
      NewsItem(
        id: 'n5',
        headline: 'Ethereum gas fees surge as DeFi activity hits 6-month high',
        source: 'Decrypt',
        url: '',
        sentimentScore: -0.22,
        publishedAt: DateTime(2026, 6, 2, 5, 0),
        symbol: 'ETH',
      ),
    ],
  ),
  CryptoAsset(
    id: 'solana',
    symbol: 'SOL',
    name: 'Solana',
    price: 178.64,
    change24h: 8.92,
    changePercent24h: 5.26,
    marketCap: 82000000000,
    volume24h: 5800000000,
    holdings: 45.0,
    avgBuyPrice: 120,
    sparkline: _sparkline(178, 24),
    sentiment: const SentimentData(
      score: 0.88,
      positive: 2134,
      negative: 189,
      neutral: 421,
      label: 'Extremely Bullish',
    ),
    ensemble: const EnsembleResult(
      bullishProbability: 0.89,
      predictedPrice: 195.0,
      priceChangePercent: 9.2,
      signal: 'STRONG BUY',
      confidence: 0.91,
      modelWeights: {'LSTM': 0.25, 'GRU': 0.28, 'GAN': 0.22, 'Hybrid': 0.25},
    ),
    recentNews: [
      NewsItem(
        id: 'n6',
        headline: 'Solana overtakes Ethereum in DEX trading volume for 3rd consecutive week',
        source: 'CoinTelegraph',
        url: '',
        sentimentScore: 0.91,
        publishedAt: DateTime(2026, 6, 2, 8, 0),
        symbol: 'SOL',
      ),
    ],
  ),
  CryptoAsset(
    id: 'avalanche',
    symbol: 'AVAX',
    name: 'Avalanche',
    price: 38.72,
    change24h: -2.14,
    changePercent24h: -5.23,
    marketCap: 16000000000,
    volume24h: 980000000,
    holdings: 120.0,
    avgBuyPrice: 45,
    sparkline: _sparkline(38, 24),
    sentiment: const SentimentData(
      score: -0.18,
      positive: 412,
      negative: 534,
      neutral: 380,
      label: 'Slightly Bearish',
    ),
    ensemble: const EnsembleResult(
      bullishProbability: 0.38,
      predictedPrice: 36.50,
      priceChangePercent: -5.7,
      signal: 'SELL',
      confidence: 0.68,
      modelWeights: {'LSTM': 0.30, 'GRU': 0.25, 'GAN': 0.20, 'Hybrid': 0.25},
    ),
    recentNews: [
      NewsItem(
        id: 'n7',
        headline: 'Avalanche subnet activity drops 40% amid broader DeFi slowdown',
        source: 'The Defiant',
        url: '',
        sentimentScore: -0.61,
        publishedAt: DateTime(2026, 6, 2, 7, 0),
        symbol: 'AVAX',
      ),
    ],
  ),
];
