import 'package:equatable/equatable.dart';

class XaiFeature extends Equatable {
  final String name;
  final double impact;
  final bool isPositive;

  const XaiFeature({
    required this.name,
    required this.impact,
    required this.isPositive,
  });

  @override
  List<Object?> get props => [name, impact, isPositive];
}

class NewsEvent extends Equatable {
  final String headline;
  final String source;
  final double sentimentScore;
  final DateTime time;

  const NewsEvent({
    required this.headline,
    required this.source,
    required this.sentimentScore,
    required this.time,
  });

  @override
  List<Object?> get props => [headline, source, sentimentScore, time];
}

class XaiExplanation extends Equatable {
  final List<XaiFeature> features;
  final String summary;

  const XaiExplanation({required this.features, required this.summary});

  @override
  List<Object?> get props => [features, summary];
}

class ModelPrediction extends Equatable {
  final String modelName;
  final double bullishProb;
  final double predictedPrice;
  final double confidence;

  const ModelPrediction({
    required this.modelName,
    required this.bullishProb,
    required this.predictedPrice,
    required this.confidence,
  });

  bool get isBullish => bullishProb > 0.5;

  @override
  List<Object?> get props => [modelName, bullishProb, predictedPrice, confidence];
}

class CandleData extends Equatable {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final List<ModelPrediction>? predictions;
  final XaiExplanation? xai;
  final NewsEvent? triggeringEvent;

  const CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.predictions,
    this.xai,
    this.triggeringEvent,
  });

  bool get isBullish => close >= open;
  double get bodySize => (close - open).abs();
  double get change => close - open;
  double get changePercent => ((close - open) / open) * 100;

  @override
  List<Object?> get props => [time, open, high, low, close, volume];
}
