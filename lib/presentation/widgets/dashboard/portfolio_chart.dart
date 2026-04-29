import 'package:flutter/material.dart';

/// Placeholder portfolio chart widget.
/// Replace with fl_chart LineChart when chart data is ready.
class PortfolioChart extends StatelessWidget {
  final List<Map<String, dynamic>> timeSeries;
  final Color lineColor;

  const PortfolioChart({
    super.key,
    required this.timeSeries,
    this.lineColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    if (timeSeries.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Chart data loading...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
      );
    }

    // Normalize values for the mini sparkline
    final values = timeSeries
        .map((e) => _toDouble(e['close'] ?? e['4. close'] ?? e['value']))
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return const SizedBox(height: 80);

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;

    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          min: minV,
          range: range == 0 ? 1 : range,
          color: lineColor,
        ),
      ),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double range;
  final Color color;

  _SparklinePainter({
    required this.values,
    required this.min,
    required this.range,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
