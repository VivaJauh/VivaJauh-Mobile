import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';

Future<RecordType?> showRecordTypePicker(BuildContext context) {
  return showModalBottomSheet<RecordType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _RecordTypePicker(),
  );
}

class _RecordTypePicker extends StatelessWidget {
  const _RecordTypePicker();

  static const _options = [
    (type: RecordType.feedTransaction, label: 'Transaksi Pakan', icon: AppIcons.feed),
    (type: RecordType.livestockEvent, label: 'Event Ternak', icon: AppIcons.livestock),
    (type: RecordType.savingsTransaction, label: 'Simpanan Anggota', icon: AppIcons.savings),
    (type: RecordType.loanRepayment, label: 'Cicilan Pinjaman', icon: AppIcons.loan),
    (type: RecordType.dailyReport, label: 'Laporan Harian', icon: AppIcons.dailyReport),
    (type: RecordType.sellerCredit, label: 'Seller Credit', icon: AppIcons.sellerCredit),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Jenis Catatan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: _options
                  .map(
                    (opt) => _TypeCard(
                      icon: opt.icon,
                      label: opt.label,
                      color: AppColors.primary,
                      onTap: () => Navigator.pop(context, opt.type),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
