import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/crypto_asset.dart';
import '../services/crypto_service.dart';

class MarketNotifier extends ChangeNotifier {
  MarketNotifier() {
    _init();
  }

  final _service = CryptoService();

  List<CryptoAsset> _allCoins = [];
  List<CryptoAsset> _filtered = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  String _query = '';
  String _sortBy = 'market_cap'; // market_cap | price | change | volume
  int _page = 1;
  bool _hasMore = true;

  List<CryptoAsset> get coins => _filtered;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String get error => _error;
  String get sortBy => _sortBy;

  // Per-coin live prices with flash state
  final Map<String, double> _livePrices = {};
  final Map<String, bool> _rising = {};
  final Map<String, bool> _flash = {};

  Map<String, double> get livePrices => _livePrices;
  bool isRising(String sym) => _rising[sym] ?? true;
  bool isFlashing(String sym) => _flash[sym] ?? false;

  StreamSubscription? _priceSub;

  void _init() {
    _service.connectPriceWebSocket();
    _priceSub = _service.priceStream.listen(_onPriceUpdate);
    _loadPage(reset: true);
    // Refresh CoinGecko data every 60s
    Timer.periodic(const Duration(seconds: 60), (_) => _loadPage(reset: true, silent: true));
  }

  Future<void> _loadPage({bool reset = false, bool silent = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      if (!silent) {
        _loading = true;
        notifyListeners();
      }
    } else {
      if (!_hasMore || _loadingMore) return;
      _loadingMore = true;
      notifyListeners();
    }

    try {
      final fresh = await _service.fetchMarkets(perPage: 100, page: _page);
      if (fresh.isEmpty) {
        _hasMore = false;
      } else {
        if (reset) {
          _allCoins = fresh;
        } else {
          // Append, dedup by id
          final ids = _allCoins.map((c) => c.id).toSet();
          _allCoins.addAll(fresh.where((c) => !ids.contains(c.id)));
        }
        // Seed live prices
        for (final c in fresh) {
          _livePrices[c.symbol] = c.price;
        }
        _page++;
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to load markets. Check your connection.';
    }

    _loading = false;
    _loadingMore = false;
    _applyFilter();
  }

  void loadMore() => _loadPage(reset: false);

  void search(String query) {
    _query = query.toLowerCase().trim();
    _applyFilter();
  }

  void sortCoins(String by) {
    _sortBy = by;
    _applyFilter();
  }

  void _applyFilter() {
    var list = List<CryptoAsset>.from(_allCoins);

    if (_query.isNotEmpty) {
      list = list.where((c) =>
          c.name.toLowerCase().contains(_query) ||
          c.symbol.toLowerCase().contains(_query)).toList();
    }

    switch (_sortBy) {
      case 'price':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'change':
        list.sort((a, b) => b.changePercent24h.compareTo(a.changePercent24h));
      case 'volume':
        list.sort((a, b) => b.volume24h.compareTo(a.volume24h));
      default: // market_cap — already sorted from API
        break;
    }

    _filtered = list;
    notifyListeners();
  }

  void _onPriceUpdate(Map<String, double> updates) {
    updates.forEach((sym, newPrice) {
      final old = _livePrices[sym];
      if (old != null) _rising[sym] = newPrice >= old;
      _livePrices[sym] = newPrice;
      _flash[sym] = true;
    });
    notifyListeners();
    // Clear flash after 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      for (final sym in updates.keys) {
        _flash[sym] = false;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    _service.disconnect();
    super.dispose();
  }
}
