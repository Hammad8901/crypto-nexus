import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/candle_data.dart';
import '../models/crypto_asset.dart';
import '../theme/app_theme.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/model_prediction_card.dart';
import '../widgets/sentiment_gauge.dart';
import '../widgets/wow_card.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoAsset asset;
  const CryptoDetailScreen({super.key, required this.asset});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<CandleData> _candles;
  String _timeframe = '4H';

  static const _timeframes = ['1H', '4H', '1D', '1W'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCandles();
  }

  void _loadCandles() {
    _candles = generateCandles(widget.asset.price, 80);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('\$#,##0.00');
    final isUp = widget.asset.changePercent24h >= 0;
    final priceColor = isUp ? AppColors.positive : AppColors.negative;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(fmt, priceColor, isUp),
            _buildTimeframes(),
            _buildChart(),
            _buildTabs(),
            Expanded(child: _buildTabViews()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NumberFormat fmt, Color priceColor, bool isUp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgGlass,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          HeroCryptoCard(
            heroTag: 'crypto_hero_${widget.asset.id}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CoinIcon(symbol: widget.asset.symbol, size: 38),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.asset.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(widget.asset.symbol, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt.format(widget.asset.price),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  Icon(isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: priceColor, size: 16),
                  Text(
                    '${widget.asset.changePercent24h.abs().toStringAsFixed(2)}%',
                    style: TextStyle(color: priceColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildTimeframes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ..._timeframes.map((tf) => GestureDetector(
                onTap: () {
                  setState(() {
                    _timeframe = tf;
                    _loadCandles();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _timeframe == tf ? AppColors.primary : AppColors.bgGlass,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _timeframe == tf ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    tf,
                    style: TextStyle(
                      color: _timeframe == tf ? Colors.black : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )),
          const Spacer(),
          const Text(
            '● Tap candle for XAI',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 9),
          ),
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(left: 4),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const Text(
            ' = news event',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return WowCard(
      glowColor: widget.asset.changePercent24h >= 0 ? AppColors.positive : AppColors.negative,
      enableShimmer: false,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 260,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: CandlestickChart(candles: _candles, symbol: widget.asset.symbol),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scaleXY(begin: 0.97, end: 1.0, curve: Curves.easeOutExpo);
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'AI Models'),
          Tab(text: 'Sentiment'),
          Tab(text: 'News'),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    final List<ModelPrediction>? preds = _candles
        .where((c) => c.predictions != null)
        .lastOrNull
        ?.predictions;

    return TabBarView(
      controller: _tabController,
      children: [
        // AI Models tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              EnsembleResultCard(
                result: widget.asset.ensemble,
                currentPrice: widget.asset.price,
              ),
              const SizedBox(height: 12),
              if (preds != null) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'INDIVIDUAL MODELS',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 8),
                ...preds.asMap().entries.map(
                  (e) => ModelPredictionCard(prediction: e.value, index: e.key),
                ),
              ],
            ],
          ),
        ),

        // Sentiment tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SentimentGauge(sentiment: widget.asset.sentiment),
        ),

        // News tab
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.asset.recentNews.length,
          itemBuilder: (ctx, i) => NewsCard(news: widget.asset.recentNews[i], index: i),
        ),
      ],
    );
  }
}

class _CoinIcon extends StatelessWidget {
  final String symbol;
  final double size;
  const _CoinIcon({required this.symbol, required this.size});

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
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, 1),
          style: TextStyle(color: color, fontSize: size * 0.38, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
