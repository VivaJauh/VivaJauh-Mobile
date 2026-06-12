import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';

class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    required this.title,
    required this.days,
    required this.values,
    this.subtitle,
    this.color,
    super.key,
  });

  final String title;
  final List<String> days;
  final List<double> values;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chartColor = color ?? AppColors.primary;
    final maxVal = values.isEmpty ? 1.0 : values.reduce(max).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: values.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendPainter(
                      values: values,
                      maxVal: maxVal,
                      color: chartColor,
                    ),
                    size: Size.infinite,
                  ),
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days.first,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                if (days.length > 2)
                  Text(
                    days[days.length ~/ 2],
                    style: const TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                Text(
                  days.last,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.maxVal,
    required this.color,
  });

  final List<double> values;
  final double maxVal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    final points = List.generate(values.length, (i) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] / maxVal) * size.height;
      return Offset(x, y.clamp(0.0, size.height));
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final pt in points) {
      canvas.drawCircle(pt, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.maxVal != maxVal || old.color != color;
}
