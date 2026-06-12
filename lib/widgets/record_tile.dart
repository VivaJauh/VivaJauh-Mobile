import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/formats.dart';
import 'app_icons.dart';
import 'app_theme.dart';
import 'status_badge.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({required this.record, this.onTap, super.key});

  final OfflineRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reader = PayloadReader(record.payloadJson);
    final icon = AppRecordStyle.icon(record.recordType);
    final color = AppRecordStyle.color(record.recordType);
    final subtitle = reader.primary.isNotEmpty ? reader.primary : null;
    final valueStr = _valueString(reader);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.recordType.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(AppIcons.time, size: 11, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(
                        AppFormats.dateShort(record.recordedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (valueStr != null)
                  Text(
                    valueStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                StatusBadge.sync(record.syncStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _valueString(PayloadReader r) {
    final qty = r.quantity;
    if (qty == 0) return null;
    return switch (record.recordType) {
      RecordType.feedTransaction => AppFormats.kg(qty.toDouble()),
      RecordType.livestockEvent => AppFormats.ekor(qty.toDouble()),
      RecordType.savingsTransaction ||
      RecordType.loanRepayment ||
      RecordType.sellerCredit => AppFormats.rupiah(qty.toDouble()),
      _ => null,
    };
  }
}
