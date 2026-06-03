import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/crypto_asset.dart';
import '../models/candle_data.dart';
import '../data/mock_data.dart' show generateCandles;

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));

  static const _geckoBase = 'https://api.coingecko.com/api/v3';
  static const _binanceBase = 'https://api.binance.com/api/v3';

  WebSocketChannel? _priceChannel;
  final _priceController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  final Map<String, double> _latestPrices = {};
  Map<String, double> get latestPrices => Map.unmodifiable(_latestPrices);

  // ── Fetch top N coins from CoinGecko ─────────────────────────────────────

  Future<List<CryptoAsset>> fetchMarkets({int perPage = 100, int page = 1}) async {
    try {
      final resp = await _dio.get(
        '$_geckoBase/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': perPage,
          'page': page,
          'sparkline': true,
          'price_change_percentage': '24h',
        },
      );
      final raw = resp.data as List;
      final assets = raw.map((c) => _parseCoinGecko(c)).toList();
      // Cache latest prices
      for (final a in assets) {
        _latestPrices[a.symbol] = a.price;
      }
      return assets;
    } on DioException catch (e) {
      debugPrint('CoinGecko error: ${e.message}');
      return _fallbackAssets();
    } catch (e) {
      debugPrint('fetchMarkets error: $e');
      return _fallbackAssets();
    }
  }

  // ── Real-time: Binance all-tickers stream ─────────────────────────────────
  // wss://stream.binance.com:9443/ws/!miniTicker@arr
  // Fires every second with ALL USDT pairs.

  void connectPriceWebSocket() {
    _disconnectWs();
    try {
      _priceChannel = WebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/ws/!miniTicker@arr'),
      );
      _priceChannel!.stream.listen(
        _handleTickerMessage,
        onError: (e) {
          debugPrint('WS error: $e — reconnecting in 4s');
          Future.delayed(const Duration(seconds: 4), connectPriceWebSocket);
        },
        onDone: () {
          debugPrint('WS closed — reconnecting in 4s');
          Future.delayed(const Duration(seconds: 4), connectPriceWebSocket);
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WS connect error: $e — falling back to simulation');
      _simulatePrices();
    }
  }

  void _handleTickerMessage(dynamic raw) {
    try {
      final List<dynamic> tickers = jsonDecode(raw as String);
      final updates = <String, double>{};
      for (final t in tickers) {
        final symbol = (t['s'] as String);
        if (!symbol.endsWith('USDT')) continue;
        final coin = symbol.replaceAll('USDT', '');
        final price = double.tryParse(t['c'].toString());
        if (price != null && price > 0) {
          updates[coin] = price;
          _latestPrices[coin] = price;
        }
      }
      if (updates.isNotEmpty) _priceController.add(updates);
    } catch (e) {
      debugPrint('Ticker parse error: $e');
    }
  }

  void _simulatePrices() {
    // Fallback: simulate ticks for known coins when WS fails
    final seeds = <String, double>{
      'BTC': 67420, 'ETH': 3812, 'SOL': 178, 'AVAX': 38,
      'BNB': 590, 'XRP': 0.52, 'ADA': 0.45, 'DOT': 7.2,
      'MATIC': 0.88, 'LINK': 14.2, 'UNI': 9.4, 'ATOM': 8.1,
    };
    _latestPrices.addAll(seeds);
    Timer.periodic(const Duration(seconds: 2), (_) {
      final updates = <String, double>{};
      seeds.forEach((sym, _) {
        final cur = _latestPrices[sym] ?? seeds[sym]!;
        final next = cur * (1 + (0.5 - DateTime.now().millisecond / 2000) * 0.002);
        _latestPrices[sym] = next;
        updates[sym] = next;
      });
      _priceController.add(updates);
    });
  }

  // ── OHLCV candles from Binance ────────────────────────────────────────────

  Future<List<CandleData>> fetchCandles(String symbol, {String interval = '4h', int limit = 80}) async {
    try {
      final resp = await _dio.get(
        '$_binanceBase/klines',
        queryParameters: {'symbol': '${symbol}USDT', 'interval': interval, 'limit': limit},
      );
      return (resp.data as List).map((k) => CandleData(
        time: DateTime.fromMillisecondsSinceEpoch(k[0] as int),
        open: double.parse(k[1].toString()),
        high: double.parse(k[2].toString()),
        low: double.parse(k[3].toString()),
        close: double.parse(k[4].toString()),
        volume: double.parse(k[5].toString()),
      )).toList();
    } catch (e) {
      debugPrint('Binance klines error: $e');
      return generateCandles(_latestPrices[symbol] ?? 100, limit);
    }
  }

  void _disconnectWs() {
    _priceChannel?.sink.close();
    _priceChannel = null;
  }

  void disconnect() => _disconnectWs();

  // ── Parsers ───────────────────────────────────────────────────────────────

  CryptoAsset _parseCoinGecko(Map<String, dynamic> c) {
    final symbol = (c['symbol'] as String).toUpperCase();
    final sparkRaw = (c['sparkline_in_7d']?['price'] as List?)?.cast<num>() ?? [];
    final spark = sparkRaw.isEmpty
        ? List.generate(24, (_) => (c['current_price'] as num).toDouble())
        : sparkRaw.map((e) => e.toDouble()).toList();
    final price = (c['current_price'] as num?)?.toDouble() ?? 0.0;
    final rank = (c['market_cap_rank'] as int?) ?? 999;

    return CryptoAsset(
      id: c['id'] as String,
      symbol: symbol,
      name: c['name'] as String,
      price: price,
      change24h: (c['price_change_24h'] as num?)?.toDouble() ?? 0.0,
      changePercent24h: (c['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      marketCap: (c['market_cap'] as num?)?.toDouble() ?? 0.0,
      volume24h: (c['total_volume'] as num?)?.toDouble() ?? 0.0,
      holdings: _defaultHoldings[symbol] ?? 0.0,
      avgBuyPrice: _defaultAvgBuy[symbol] ?? price,
      sparkline: spark,
      sentiment: _defaultSentiment[symbol] ??
          SentimentData(
            score: (c['price_change_percentage_24h'] as num?)?.toDouble().clamp(-1.0, 1.0) ?? 0.0,
            positive: 0, negative: 0, neutral: 100,
            label: ((c['price_change_percentage_24h'] as num?)?.toDouble() ?? 0) > 0 ? 'Bullish' : 'Bearish',
          ),
      ensemble: _defaultEnsemble[symbol] ?? EnsembleResult(
        bullishProbability: ((c['price_change_percentage_24h'] as num?)?.toDouble() ?? 0) > 0 ? 0.65 : 0.35,
        predictedPrice: price * 1.05,
        priceChangePercent: 5.0,
        signal: ((c['price_change_percentage_24h'] as num?)?.toDouble() ?? 0) > 0 ? 'BUY' : 'HOLD',
        confidence: 0.70,
        modelWeights: const {'LSTM': 0.30, 'GRU': 0.25, 'GAN': 0.20, 'Hybrid': 0.25},
      ),
      recentNews: const [],
    );
  }

  List<CryptoAsset> _fallbackAssets() {
    // Return minimal fallback list if API fails
    return const [];
  }

  static const _defaultHoldings = {
    'BTC': 0.42, 'ETH': 3.5, 'SOL': 45.0, 'AVAX': 120.0,
  };
  static const _defaultAvgBuy = {
    'BTC': 52000.0, 'ETH': 2800.0, 'SOL': 120.0, 'AVAX': 45.0,
  };
  static const _defaultSentiment = {
    'BTC': SentimentData(score: 0.74, positive: 1842, negative: 312, neutral: 543, label: 'Very Bullish'),
    'ETH': SentimentData(score: 0.42, positive: 923, negative: 487, neutral: 612, label: 'Slightly Bullish'),
    'SOL': SentimentData(score: 0.88, positive: 2134, negative: 189, neutral: 421, label: 'Extremely Bullish'),
    'AVAX': SentimentData(score: -0.18, positive: 412, negative: 534, neutral: 380, label: 'Slightly Bearish'),
  };
  static const _defaultEnsemble = {
    'BTC': EnsembleResult(bullishProbability: 0.81, predictedPrice: 71200, priceChangePercent: 5.6, signal: 'STRONG BUY', confidence: 0.87, modelWeights: {'LSTM': 0.30, 'GRU': 0.25, 'GAN': 0.20, 'Hybrid': 0.25}),
    'ETH': EnsembleResult(bullishProbability: 0.58, predictedPrice: 3950, priceChangePercent: 3.6, signal: 'BUY', confidence: 0.72, modelWeights: {'LSTM': 0.28, 'GRU': 0.30, 'GAN': 0.22, 'Hybrid': 0.20}),
    'SOL': EnsembleResult(bullishProbability: 0.89, predictedPrice: 195, priceChangePercent: 9.2, signal: 'STRONG BUY', confidence: 0.91, modelWeights: {'LSTM': 0.25, 'GRU': 0.28, 'GAN': 0.22, 'Hybrid': 0.25}),
    'AVAX': EnsembleResult(bullishProbability: 0.38, predictedPrice: 36.5, priceChangePercent: -5.7, signal: 'SELL', confidence: 0.68, modelWeights: {'LSTM': 0.30, 'GRU': 0.25, 'GAN': 0.20, 'Hybrid': 0.25}),
  };
}
