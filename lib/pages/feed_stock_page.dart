import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';

class FeedStockPage extends StatelessWidget {
  const FeedStockPage({
    required this.session,
    required this.records,
    required this.online,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    required this.onRefreshRecords,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;
  final Future<void> Function() onRefreshRecords;

  @override
  Widget build(BuildContext context) {
    final summary = Aggregator.computeFeedStock(records);

    return Scaffold(
      appBar: AppBar(title: const Text('Stok Pakan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordFormPage(
              session: session,
              recordType: RecordType.feedTransaction,
              onSave: onAddRecord,
            ),
          ),
        ),
        child: const Icon(AppIcons.add),
      ),
      body: RefreshIndicator(
        onRefresh: onRefreshRecords,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.feed, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Total Stok Pakan',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormats.kg(summary.totalBalanceKg),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stat cards
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.stockIn,
                  value: AppFormats.kg(summary.totalInKg),
                  label: 'Total Masuk',
                  color: AppColors.success,
                ),
                StatCard(
                  icon: AppIcons.stockOut,
                  value: AppFormats.kg(summary.totalOutKg),
                  label: 'Total Keluar',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatCard(
              icon: AppIcons.damaged,
              value: AppFormats.kg(summary.totalDamagedKg),
              label: 'Total Rusak',
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),

            // Bar chart by type
            if (summary.balanceByType.isNotEmpty) ...[
              SectionCard(
                child: HBarChart(
                  title: 'Stok per Jenis Pakan',
                  unit: ' kg',
                  items: (summary.balanceByType.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .map(
                        (e) => HBarItem(
                          label: e.key,
                          value: e.value,
                          color: AppColors.primary,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // History
            Text(
              'Riwayat Transaksi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (summary.history.isEmpty)
              EmptyState(
                icon: AppIcons.emptyInbox,
                title: 'Belum ada transaksi',
                message: 'Catat transaksi pakan masuk atau keluar.',
              )
            else
              ...summary.history
                  .take(30)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RecordTile(
                        record: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordDetailPage(
                              session: session,
                              record: r,
                              onUpdateRecord: onUpdateRecord,
                              onDeleteRecord: onDeleteRecord,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
