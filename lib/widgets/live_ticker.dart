import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/crypto_asset.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';

class LivePriceTicker extends StatefulWidget {
  final List<CryptoAsset> assets;
  const LivePriceTicker({super.key, required this.assets});

  @override
  State<LivePriceTicker> createState() => _LivePriceTickerState();
}

class _LivePriceTickerState extends State<LivePriceTicker> {
  final Map<String, double> _prices = {};
  final Map<String, bool> _rising = {};
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    for (final a in widget.assets) {
      _prices[a.symbol] = a.price;
      _rising[a.symbol] = true;
    }
    _sub = CryptoService().priceStream.listen((update) {
      if (!mounted) return;
      update.forEach((sym, newPrice) {
        setState(() {
          final old = _prices[sym] ?? newPrice;
          _rising[sym] = newPrice >= old;
          _prices[sym] = newPrice;
        });
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: AppColors.bgCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: AppColors.primaryDim,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppColors.positive, size: 6),
                SizedBox(width: 5),
                Text('LIVE', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.assets.length,
              itemBuilder: (_, i) {
                final a = widget.assets[i];
                final price = _prices[a.symbol] ?? a.price;
                final isUp = _rising[a.symbol] ?? true;
                return _TickerItem(
                  symbol: a.symbol,
                  price: price,
                  change: a.changePercent24h,
                  isUp: isUp,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerItem extends StatefulWidget {
  final String symbol;
  final double price;
  final double change;
  final bool isUp;

  const _TickerItem({required this.symbol, required this.price, required this.change, required this.isUp});

  @override
  State<_TickerItem> createState() => _TickerItemState();
}

class _TickerItemState extends State<_TickerItem> {
  double? _prevPrice;

  @override
  void didUpdateWidget(_TickerItem old) {
    super.didUpdateWidget(old);
    _prevPrice = old.price;
  }

  @override
  Widget build(BuildContext context) {
    final priceColor = widget.isUp ? AppColors.positive : AppColors.negative;
    final changed = _prevPrice != null && _prevPrice != widget.price;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.symbol, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: changed ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text('\$${_fmt(widget.price)}'),
          ).animate(key: ValueKey(widget.price)).then(delay: 200.ms).custom(
            duration: 200.ms,
            begin: 0,
            end: 1,
            builder: (_, v, child) => Opacity(opacity: 0.5 + 0.5 * v, child: child),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.change >= 0 ? '+' : ''}${widget.change.toStringAsFixed(2)}%',
            style: TextStyle(color: priceColor, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) {
    if (price >= 10000) return '${(price / 1000).toStringAsFixed(2)}k';
    if (price >= 1000) return price.toStringAsFixed(2);
    return price.toStringAsFixed(3);
  }
}
