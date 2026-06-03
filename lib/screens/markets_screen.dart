import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/crypto_asset.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import 'crypto_detail_screen.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  late MarketNotifier _market;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _market = MarketNotifier();
    _market.addListener(_rebuild);
    _scrollCtrl.addListener(_onScroll);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 400) {
      _market.loadMore();
    }
  }

  @override
  void dispose() {
    _market.removeListener(_rebuild);
    _market.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _Header(market: _market, searchCtrl: _searchCtrl),
          _SortBar(market: _market),
          Expanded(child: _Body(market: _market, scrollCtrl: _scrollCtrl)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final MarketNotifier market;
  final TextEditingController searchCtrl;
  const _Header({required this.market, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Markets', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              if (!market.loading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(6)),
                  child: Text('${market.coins.length} coins', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              const Spacer(),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.positiveDim, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.positive.withOpacity(0.3))),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.positive, size: 6),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: AppColors.positive, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: AppColors.textTertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: market.search,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search Bitcoin, ETH, SOL...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { searchCtrl.clear(); market.search(''); },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.clear, color: AppColors.textTertiary, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort bar ──────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final MarketNotifier market;
  const _SortBar({required this.market});

  static const _opts = [
    ('market_cap', 'Market Cap'),
    ('change', '24h Change'),
    ('volume', 'Volume'),
    ('price', 'Price'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: _opts.length,
        itemBuilder: (_, i) {
          final (key, label) = _opts[i];
          final active = market.sortBy == key;
          return GestureDetector(
            onTap: () => market.sortCoins(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.black : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final MarketNotifier market;
  final ScrollController scrollCtrl;
  const _Body({required this.market, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    if (market.loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: 12,
        itemBuilder: (_, i) => _SkeletonRow(delay: i * 40),
      );
    }

    if (market.error.isNotEmpty && market.coins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text(market.error, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => market.search(''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)),
                child: const Text('Retry', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    if (market.coins.isEmpty) {
      return const Center(
        child: Text('No coins found.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: market.coins.length + (market.loadingMore ? 3 : 0),
      itemBuilder: (ctx, i) {
        if (i >= market.coins.length) return const _SkeletonRow(delay: 0);
        return _CoinRow(
          asset: market.coins[i],
          rank: i + 1,
          market: market,
          onTap: () => Navigator.push(
            ctx,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CryptoDetailScreen(asset: market.coins[i]),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutExpo)),
                  child: child,
                ),
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          ),
        );
      },
    );
  }
}

// ── Coin row ──────────────────────────────────────────────────────────────────

class _CoinRow extends StatelessWidget {
  final CryptoAsset asset;
  final int rank;
  final MarketNotifier market;
  final VoidCallback onTap;

  const _CoinRow({required this.asset, required this.rank, required this.market, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final livePrice = market.livePrices[asset.symbol] ?? asset.price;
    final isUp = asset.changePercent24h >= 0;
    final isRising = market.isRising(asset.symbol);
    final flashing = market.isFlashing(asset.symbol);
    final priceColor = isRising ? AppColors.positive : AppColors.negative;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: flashing
              ? (isRising ? AppColors.positiveDim : AppColors.negativeDim)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: flashing
                ? (isRising ? AppColors.positive.withOpacity(0.35) : AppColors.negative.withOpacity(0.35))
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 28,
              child: Text('$rank', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            ),

            // Coin icon
            _CoinAvatar(symbol: asset.symbol, name: asset.name),
            const SizedBox(width: 10),

            // Name + symbol
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.symbol, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(asset.name, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Sparkline
            SizedBox(
              width: 60, height: 28,
              child: CustomPaint(painter: _SparkPainter(data: asset.sparkline, isUp: isUp)),
            ),
            const SizedBox(width: 10),

            // Price + change
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: Offset(0, isRising ? -0.3 : 0.3), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      key: ValueKey(livePrice.toStringAsFixed(2)),
                      _fmtPrice(livePrice),
                      style: TextStyle(
                        color: flashing ? priceColor : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isUp ? AppColors.positiveDim : AppColors.negativeDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isUp ? '+' : ''}${asset.changePercent24h.toStringAsFixed(2)}%',
                      style: TextStyle(color: isUp ? AppColors.positive : AppColors.negative, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: (rank.clamp(1, 20) * 18)))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.04, end: 0);
  }

  String _fmtPrice(double p) {
    if (p >= 10000) return '\$${NumberFormat('#,##0').format(p)}';
    if (p >= 1000) return '\$${p.toStringAsFixed(2)}';
    if (p >= 1) return '\$${p.toStringAsFixed(3)}';
    return '\$${p.toStringAsFixed(6)}';
  }
}

// ── Coin avatar ───────────────────────────────────────────────────────────────

class _CoinAvatar extends StatelessWidget {
  final String symbol, name;
  const _CoinAvatar({required this.symbol, required this.name});

  static const Map<String, Color> _knownColors = {
    'BTC': Color(0xFFF7931A), 'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF), 'AVAX': Color(0xFFE84142),
    'BNB': Color(0xFFF3BA2F), 'XRP': Color(0xFF00AAE4),
    'ADA': Color(0xFF0033AD), 'DOGE': Color(0xFFC2A633),
    'DOT': Color(0xFFE6007A), 'MATIC': Color(0xFF8247E5),
    'LINK': Color(0xFF2A5ADA), 'UNI': Color(0xFFFF007A),
    'ATOM': Color(0xFF6F4E7C), 'LTC': Color(0xFF345D9D),
    'TRX': Color(0xFFEB0029), 'NEAR': Color(0xFF00EC97),
  };

  @override
  Widget build(BuildContext context) {
    final color = _knownColors[symbol] ?? _colorFromName(name);
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Center(
        child: Text(
          symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    final hue = name.codeUnits.fold(0, (s, c) => s + c) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.55).toColor();
  }
}

// ── Sparkline painter ─────────────────────────────────────────────────────────

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final bool isUp;
  const _SparkPainter({required this.data, required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range == 0) return;
    final color = isUp ? AppColors.positive : AppColors.negative;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * (1 - (data[i] - min) / range);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.isUp != isUp;
}

// ── Skeleton loading row ──────────────────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  final int delay;
  const _SkeletonRow({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _bone(28, 10),
          const SizedBox(width: 8),
          _circle(36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_bone(60, 12), const SizedBox(height: 4), _bone(40, 9)])),
          _bone(60, 28),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_bone(70, 12), const SizedBox(height: 4), _bone(45, 9)]),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 400.ms);
  }

  Widget _bone(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
  );

  Widget _circle(double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.border),
  );
}
