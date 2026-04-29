import 'package:flutter/material.dart';
import '../common/glass_container.dart';

/// Lightweight sparkline chart for stock price history using CustomPainter.
/// Swap out for fl_chart LineChart if you need interactive tooltips.
class StockPriceChart extends StatelessWidget {
  final List<Map<String, dynamic>> timeSeries;
  final bool isPositive;

  const StockPriceChart({
    super.key,
    required this.timeSeries,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    if (timeSeries.isEmpty) {
      return GlassContainer(
        height: 140,
        borderRadius: BorderRadius.circular(16),
        child: const Center(
          child: Text(
            'No chart data',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
      );
    }

    final rawValues = timeSeries
        .map((e) => _toDouble(e['close'] ?? e['4. close'] ?? e['c']))
        .where((v) => v > 0)
        .toList();

    if (rawValues.isEmpty) return const SizedBox(height: 140);

    final minV = rawValues.reduce((a, b) => a < b ? a : b);
    final maxV = rawValues.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;

    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _ChartPainter(
          values: rawValues,
          min: minV,
          range: range == 0 ? 1 : range,
          color: color,
        ),
      ),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double range;
  final Color color;

  const _ChartPainter({
    required this.values,
    required this.min,
    required this.range,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fill = Path();

    final padding = const EdgeInsets.symmetric(vertical: 8);
    final h = size.height - padding.vertical;

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = padding.top + h - ((values[i] - min) / range) * h;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }

    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);

    // Last price dot
    final lastX = size.width;
    final lastY = padding.top +
        h -
        ((values.last - min) / range) * h;
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      7,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
