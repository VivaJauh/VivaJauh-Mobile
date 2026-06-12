import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    required this.session,
    required this.records,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;

  @override
  Widget build(BuildContext context) {
    final feedSummary = Aggregator.computeFeedStock(records);
    final livestockSummary = Aggregator.computeLivestock(records);
    final savingsSummary = Aggregator.computeSavingsLoan(records);
    final syncDelay = Aggregator.computeSyncDelays(records);

    // Last 14 days sync data
    final now = DateTime.now();
    final days14 = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));
    final dailyCounts = days14.map((day) {
      return records
          .where((r) =>
              r.recordedAt.year == day.year &&
              r.recordedAt.month == day.month &&
              r.recordedAt.day == day.day)
          .length
          .toDouble();
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Activity trend
          TrendChartCard(
            title: 'Aktivitas 14 Hari Terakhir',
            days: days14.map((d) => AppFormats.dateDay(d)).toList(),
            values: dailyCounts,
            subtitle: '${records.length} catatan total',
          ),
          const SizedBox(height: 16),

          // Feed summary
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Pakan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                StatCardRow(
                  children: [
                    StatCard(
                      icon: AppIcons.stockIn,
                      value: AppFormats.kg(feedSummary.totalInKg),
                      label: 'Total Masuk',
                      color: AppColors.success,
                    ),
                    StatCard(
                      icon: AppIcons.stockOut,
                      value: AppFormats.kg(feedSummary.totalOutKg),
                      label: 'Total Keluar',
                      color: AppColors.danger,
                    ),
                  ],
                ),
                if (feedSummary.balanceByType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HBarChart(
                    title: 'Stok per Jenis',
                    unit: ' kg',
                    items: feedSummary.balanceByType.entries
                        .map(
                          (e) => HBarItem(
                            label: e.key,
                            value: e.value,
                            color: AppColors.primary,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Livestock summary
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Ternak',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                StatCardRow(
                  children: [
                    StatCard(
                      icon: AppIcons.livestock,
                      value: AppFormats.ekor(livestockSummary.totalPopulation),
                      label: 'Populasi',
                      color: AppColors.primary,
                    ),
                    StatCard(
                      icon: AppIcons.death,
                      value: AppFormats.ekor(livestockSummary.totalDeaths),
                      label: 'Kematian',
                      color: AppColors.danger,
                    ),
                  ],
                ),
                if (livestockSummary.populationByType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HBarChart(
                    title: 'Populasi per Jenis',
                    unit: ' ekor',
                    items: livestockSummary.populationByType.entries
                        .map(
                          (e) => HBarItem(
                            label: e.key,
                            value: e.value,
                            color: AppColors.secondary,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Savings summary
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simpan Pinjam',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _SumRow(label: 'Total Setor', value: AppFormats.rupiah(savingsSummary.totalDeposits)),
                _SumRow(label: 'Total Tarik', value: AppFormats.rupiah(savingsSummary.totalWithdrawals)),
                _SumRow(label: 'Saldo Bersih', value: AppFormats.rupiah(savingsSummary.savingsBalance), bold: true),
                _SumRow(label: 'Total Cicilan', value: AppFormats.rupiah(savingsSummary.totalRepayments)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sync delay summary
          if (syncDelay.entries.isNotEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delay Sinkronisasi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SumRow(
                    label: 'Rata-rata',
                    value: _formatDuration(syncDelay.averageDelay),
                  ),
                  _SumRow(
                    label: 'Maksimum',
                    value: _formatDuration(syncDelay.maxDelay),
                  ),
                  _SumRow(
                    label: 'Sampel',
                    value: '${syncDelay.entries.length} catatan',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays} hari';
    if (d.inHours > 0) return '${d.inHours} jam';
    if (d.inMinutes > 0) return '${d.inMinutes} menit';
    return '${d.inSeconds} detik';
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: bold ? AppColors.primaryDark : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
