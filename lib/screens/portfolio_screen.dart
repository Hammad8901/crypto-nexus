import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/crypto_asset.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../widgets/crypto_card.dart';
import '../widgets/wow_card.dart';
import 'crypto_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final Map<String, double> _livePrices = {};
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    // Seed with mock prices
    for (final a in mockCryptos) _livePrices[a.symbol] = a.price;
    _sub = CryptoService().priceStream.listen((updates) {
      if (!mounted) return;
      setState(() => _livePrices.addAll(updates));
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  // Rebuild each asset with its live price
  List<CryptoAsset> get _liveAssets => mockCryptos.map((a) {
    final lp = _livePrices[a.symbol] ?? a.price;
    return CryptoAsset(
      id: a.id, symbol: a.symbol, name: a.name,
      price: lp,
      change24h: lp - a.avgBuyPrice,
      changePercent24h: a.changePercent24h,
      marketCap: a.marketCap, volume24h: a.volume24h,
      holdings: a.holdings, avgBuyPrice: a.avgBuyPrice,
      sparkline: a.sparkline, sentiment: a.sentiment,
      ensemble: a.ensemble, recentNews: a.recentNews,
    );
  }).toList();

  @override
  Widget build(BuildContext context) {
    final assets = _liveAssets;
    final totalValue = assets.fold(0.0, (sum, a) => sum + a.totalValue);
    final totalPnl = assets.fold(0.0, (sum, a) => sum + a.pnl);
    final totalPnlPct = totalValue > 0 ? (totalPnl / (totalValue - totalPnl)) * 100 : 0.0;
    final fmt = NumberFormat('\$#,##0.00');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _DramaticHeader(
              totalValue: totalValue,
              totalPnl: totalPnl,
              totalPnlPct: totalPnlPct,
              fmt: fmt,
              assets: assets,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Text('HOLDINGS', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const Spacer(),
                  Text('${assets.length} assets', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => CryptoPortfolioCard(
                asset: assets[i],
                index: i,
                onTap: () => Navigator.push(
                  context,
                  _HeroPageRoute(page: CryptoDetailScreen(asset: assets[i])),
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

/// Custom route: shared-element + slide from bottom with spring physics
class _HeroPageRoute extends PageRouteBuilder {
  final Widget page;
  _HeroPageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, secondAnim, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutExpo);
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

// ─── Dramatic portfolio header ────────────────────────────────────────────────

class _DramaticHeader extends StatefulWidget {
  final double totalValue, totalPnl, totalPnlPct;
  final NumberFormat fmt;
  final List assets;

  const _DramaticHeader({
    required this.totalValue,
    required this.totalPnl,
    required this.totalPnlPct,
    required this.fmt,
    required this.assets,
  });

  @override
  State<_DramaticHeader> createState() => _DramaticHeaderState();
}

class _DramaticHeaderState extends State<_DramaticHeader>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.totalPnl >= 0;
    final pnlColor = isProfit ? AppColors.positive : AppColors.negative;
    final fmt2 = NumberFormat('\$#,##0.##');

    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.04 + 0.03 * sin(_bgCtrl.value * pi)),
              Colors.transparent,
              AppColors.secondary.withOpacity(0.03 + 0.02 * cos(_bgCtrl.value * pi)),
            ],
          ),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Portfolio', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                  Text(
                    'Updated just now',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ).animate(delay: 300.ms).fadeIn(),
                ],
              ),
              const Spacer(),
              _PulsingDot(),
            ],
          ),

          const SizedBox(height: 28),

          // Giant value with ExplosiveMetric
          ExplosiveMetric(
            label: 'TOTAL VALUE',
            value: widget.fmt.format(widget.totalValue),
            color: AppColors.textPrimary,
            fontSize: 40,
          ),

          const SizedBox(height: 10),

          // P&L row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pnlColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: pnlColor, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      '${isProfit ? '+' : ''}${fmt2.format(widget.totalPnl)}',
                      style: TextStyle(color: pnlColor, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms).scaleXY(begin: 0.9, end: 1),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.totalPnlPct >= 0 ? '+' : ''}${widget.totalPnlPct.toStringAsFixed(2)}%',
                  style: TextStyle(color: pnlColor, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms).scaleXY(begin: 0.9, end: 1),
              const Spacer(),
              const Text('All time', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 20),

          // Allocation bar with animated fill
          _AnimatedAllocationBar(assets: widget.assets, totalValue: widget.totalValue),

          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _QuickStat(label: 'Best', value: '+${_bestAsset(widget.assets)}%', color: AppColors.positive, delay: 200),
              _divider(),
              _QuickStat(label: 'Worst', value: '${_worstAsset(widget.assets)}%', color: AppColors.negative, delay: 300),
              _divider(),
              _QuickStat(label: 'Assets', value: '${widget.assets.length}', color: AppColors.primary, delay: 400),
              _divider(),
              _QuickStat(label: 'AI Signal', value: 'BULLISH', color: AppColors.positive, delay: 500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 10), color: AppColors.border);

  String _bestAsset(List assets) {
    final best = assets.fold(assets[0], (best, a) => a.changePercent24h > best.changePercent24h ? a : best);
    return best.changePercent24h.toStringAsFixed(1);
  }

  String _worstAsset(List assets) {
    final worst = assets.fold(assets[0], (w, a) => a.changePercent24h < w.changePercent24h ? a : w);
    return worst.changePercent24h.toStringAsFixed(1);
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final int delay;
  const _QuickStat({required this.label, required this.value, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0);
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.positive,
              boxShadow: [BoxShadow(color: AppColors.positive.withOpacity(_ctrl.value * 0.8), blurRadius: 8, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 5),
          const Text('LIVE', style: TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _AnimatedAllocationBar extends StatefulWidget {
  final List assets;
  final double totalValue;
  const _AnimatedAllocationBar({required this.assets, required this.totalValue});

  @override
  State<_AnimatedAllocationBar> createState() => _AnimatedAllocationBarState();
}

class _AnimatedAllocationBarState extends State<_AnimatedAllocationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _colors = [Color(0xFFF7931A), Color(0xFF627EEA), Color(0xFF9945FF), Color(0xFFE84142)];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Row(
                children: List.generate(widget.assets.length, (i) {
                  final pct = widget.assets[i].totalValue / widget.totalValue;
                  final animPct = pct * CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic).value;
                  return Expanded(
                    flex: (animPct * 1000).round().clamp(1, 1000),
                    child: Container(
                      color: _colors[i % _colors.length],
                      margin: const EdgeInsets.only(right: 1),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(widget.assets.length, (i) {
              final pct = (widget.assets[i].totalValue / widget.totalValue * 100);
              return Expanded(
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('${widget.assets[i].symbol} ${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
