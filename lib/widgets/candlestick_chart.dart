import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/candle_data.dart';
import '../theme/app_theme.dart';

class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;
  final String symbol;

  const CandlestickChart({super.key, required this.candles, required this.symbol});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  Offset? _tapPosition;
  late AnimationController _tooltipController;

  @override
  void initState() {
    super.initState();
    _tooltipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _tooltipController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d, BoxConstraints constraints) {
    final candleW = constraints.maxWidth / widget.candles.length;
    final idx = (d.localPosition.dx / candleW).floor().clamp(0, widget.candles.length - 1);
    setState(() {
      _selectedIndex = idx;
      _tapPosition = d.localPosition;
    });
    _tooltipController.forward(from: 0);
  }

  void _onTapUp(TapUpDetails _) {
    _tooltipController.reverse().then((_) {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (d) => _onTapDown(d, constraints),
        onTapUp: _onTapUp,
        onTapCancel: () => _tooltipController.reverse().then(
              (_) => mounted ? setState(() => _selectedIndex = null) : null,
            ),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CandlePainter(
                candles: widget.candles,
                selectedIndex: _selectedIndex,
              ),
            ),
            if (_selectedIndex != null && _tapPosition != null)
              _XaiTooltipOverlay(
                candle: widget.candles[_selectedIndex!],
                position: _tapPosition!,
                chartSize: Size(constraints.maxWidth, constraints.maxHeight),
                controller: _tooltipController,
                symbol: widget.symbol,
              ),
          ],
        ),
      );
    });
  }
}

class _CandlePainter extends CustomPainter {
  final List<CandleData> candles;
  final int? selectedIndex;

  _CandlePainter({required this.candles, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final allPrices = candles.expand((c) => [c.high, c.low]).toList();
    final maxP = allPrices.reduce(max);
    final minP = allPrices.reduce(min);
    final priceRange = maxP - minP;
    if (priceRange == 0) return;

    const topPad = 20.0;
    const bottomPad = 50.0;
    const rightPad = 64.0;
    final chartH = size.height - topPad - bottomPad;
    final chartW = size.width - rightPad;

    double py(double price) =>
        topPad + chartH * (1 - (price - minP) / priceRange);

    final candleW = chartW / candles.length;
    final bodyW = (candleW * 0.55).clamp(3.0, 12.0);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPad + chartH * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
      final price = maxP - (priceRange * i / gridLines);
      final label = _formatPrice(price);
      _drawText(canvas, label, Offset(chartW + 4, y - 7),
          AppColors.textTertiary, 10);
    }

    // Volume bars
    final maxVol = candles.map((c) => c.volume).reduce(max);
    final volH = chartH * 0.12;
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleW + candleW / 2;
      final barH = (c.volume / maxVol) * volH;
      final color = c.isBullish
          ? AppColors.positive.withOpacity(0.25)
          : AppColors.negative.withOpacity(0.25);
      canvas.drawRect(
        Rect.fromLTWH(x - bodyW / 2, size.height - bottomPad - barH + 4, bodyW, barH),
        Paint()..color = color,
      );
    }

    // Candles
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleW + candleW / 2;
      final isSelected = i == selectedIndex;

      final bullColor =
          isSelected ? AppColors.positive : AppColors.positive.withOpacity(0.85);
      final bearColor =
          isSelected ? AppColors.negative : AppColors.negative.withOpacity(0.85);
      final color = c.isBullish ? bullColor : bearColor;

      // Selection glow
      if (isSelected) {
        canvas.drawLine(
          Offset(x, topPad),
          Offset(x, size.height - bottomPad),
          Paint()
            ..color = color.withOpacity(0.15)
            ..strokeWidth = candleW,
        );
      }

      // Wick
      canvas.drawLine(
        Offset(x, py(c.high)),
        Offset(x, py(c.low)),
        Paint()
          ..color = color.withOpacity(isSelected ? 1.0 : 0.7)
          ..strokeWidth = 1.2,
      );

      // Body
      final bodyTop = py(max(c.open, c.close));
      final bodyBot = py(min(c.open, c.close));
      final bodyRect = Rect.fromLTWH(
        x - bodyW / 2, bodyTop, bodyW, (bodyBot - bodyTop).clamp(1.5, double.infinity),
      );

      // News event indicator dot
      if (c.triggeringEvent != null) {
        canvas.drawCircle(
          Offset(x, py(c.high) - 6),
          3.0,
          Paint()..color = AppColors.accent,
        );
      }

      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(
            RRect.fromRectAndRadius(bodyRect.inflate(2), const Radius.circular(2)),
            glowPaint);
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
        Paint()..color = color,
      );
    }

    // Date labels
    final dateFormat = DateFormat('MM/dd HH:mm');
    final step = (candles.length / 5).ceil();
    for (int i = 0; i < candles.length; i += step) {
      final x = i * candleW + candleW / 2;
      _drawText(
        canvas,
        dateFormat.format(candles[i].time),
        Offset(x - 22, size.height - bottomPad + 8),
        AppColors.textTertiary,
        9,
      );
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(1)}k';
    return '\$${price.toStringAsFixed(2)}';
  }

  void _drawText(Canvas c, String text, Offset offset, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w500),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(c, offset);
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.candles != candles || old.selectedIndex != selectedIndex;
}

class _XaiTooltipOverlay extends StatelessWidget {
  final CandleData candle;
  final Offset position;
  final Size chartSize;
  final AnimationController controller;
  final String symbol;

  const _XaiTooltipOverlay({
    required this.candle,
    required this.position,
    required this.chartSize,
    required this.controller,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    const tooltipW = 280.0;
    const tooltipH = 380.0;
    final hasXai = candle.xai != null;
    final effectiveH = hasXai ? tooltipH : 180.0;

    double dx = position.dx - tooltipW / 2;
    double dy = position.dy - effectiveH - 12;
    if (dx < 8) dx = 8;
    if (dx + tooltipW > chartSize.width - 8) dx = chartSize.width - tooltipW - 8;
    if (dy < 8) dy = 8;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Positioned(
        left: dx,
        top: dy,
        child: Opacity(
          opacity: controller.value,
          child: Transform.scale(
            scale: 0.92 + 0.08 * controller.value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      ),
      child: Container(
        width: tooltipW,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderBright),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildPriceRow(),
            const Divider(color: AppColors.border, height: 1),
            if (candle.predictions != null) _buildPredictions(),
            if (candle.xai != null) ...[
              const Divider(color: AppColors.border, height: 1),
              _buildXai(),
            ],
            if (candle.triggeringEvent != null) ...[
              const Divider(color: AppColors.border, height: 1),
              _buildNewsEvent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final fmt = DateFormat('MMM d, HH:mm');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: candle.isBullish ? AppColors.positive : AppColors.negative,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$symbol · ${fmt.format(candle.time)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: candle.isBullish ? AppColors.positiveDim : AppColors.negativeDim,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${candle.changePercent >= 0 ? '+' : ''}${candle.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: candle.isBullish ? AppColors.positive : AppColors.negative,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    final fmt = NumberFormat('\$#,##0.00');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          _priceItem('O', candle.open, fmt),
          _priceItem('H', candle.high, fmt),
          _priceItem('L', candle.low, fmt),
          _priceItem('C', candle.close, fmt),
        ],
      ),
    );
  }

  Widget _priceItem(String label, double price, NumberFormat fmt) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
          Text(
            fmt.format(price),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictions() {
    final preds = candle.predictions!;
    final colors = {
      'LSTM': AppColors.lstm,
      'GRU': AppColors.gru,
      'GAN': AppColors.gan,
      'Hybrid': AppColors.custom,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖  AI MODEL SIGNALS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...preds.map((p) => _modelRow(p, colors[p.modelName] ?? AppColors.primary)),
        ],
      ),
    );
  }

  Widget _modelRow(ModelPrediction p, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              p.modelName,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: p.bullishProb,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(p.bullishProb * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: p.isBullish ? AppColors.positive : AppColors.negative,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXai() {
    final xai = candle.xai!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊  XAI FEATURE IMPACT',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...xai.features.map((f) => _xaiRow(f)),
        ],
      ),
    );
  }

  Widget _xaiRow(XaiFeature f) {
    final color = f.isPositive ? AppColors.positive : AppColors.negative;
    final maxImpact = candle.xai!.features.map((x) => x.impact).reduce(max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              f.name,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: f.impact / maxImpact,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${f.isPositive ? '+' : '-'}${f.impact.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsEvent() {
    final e = candle.triggeringEvent!;
    final isPos = e.sentimentScore > 0;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📰  TRIGGERING EVENT',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isPos ? AppColors.positiveDim : AppColors.negativeDim,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sentiment: ${e.sentimentScore >= 0 ? '+' : ''}${e.sentimentScore.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isPos ? AppColors.positive : AppColors.negative,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            e.headline,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            e.source,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
