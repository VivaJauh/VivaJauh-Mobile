import 'package:flutter/material.dart';

import 'app_theme.dart';

class HBarItem {
  const HBarItem({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;
}

class HBarChart extends StatelessWidget {
  const HBarChart({required this.items, this.title, this.unit = '', super.key});

  final List<HBarItem> items;
  final String? title;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final maxVal = items.isEmpty
        ? 1.0
        : items.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tidak ada data',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          )
        else
          ...items.map((item) => _HBarRow(item: item, maxVal: maxVal, unit: unit)),
      ],
    );
  }
}

class _HBarRow extends StatelessWidget {
  const _HBarRow({required this.item, required this.maxVal, required this.unit});

  final HBarItem item;
  final double maxVal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ratio = maxVal <= 0 ? 0.0 : (item.value.abs() / maxVal).clamp(0.0, 1.0);
    final barColor = item.color ?? AppColors.primary;
    final valueStr = item.value.abs() >= 1000
        ? '${(item.value.abs() / 1000).toStringAsFixed(1)}k'
        : item.value.abs() == item.value.abs().truncateToDouble()
            ? item.value.abs().toStringAsFixed(0)
            : item.value.abs().toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$valueStr$unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
