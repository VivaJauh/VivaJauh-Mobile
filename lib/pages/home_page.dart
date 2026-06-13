import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_applications_page.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';
import 'records_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.session,
    required this.records,
    required this.syncing,
    required this.online,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    required this.onSync,
    required this.onRefreshRecords,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final bool syncing;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;
  final Future<void> Function() onSync;
  final Future<void> Function() onRefreshRecords;

  int get _pendingCount => records
      .where(
        (r) =>
            r.syncStatus == SyncStatus.pending ||
            r.syncStatus == SyncStatus.failed,
      )
      .length;

  List<OfflineRecord> get _recent =>
      (records.toList()..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)))
          .take(5)
          .toList();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 18
        ? 'Selamat sore'
        : 'Selamat malam';

    final feedSummary = Aggregator.computeFeedStock(records);
    final livestockSummary = Aggregator.computeLivestock(records);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefreshRecords,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            OfflineBanner(online: online, pendingCount: _pendingCount),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pendingCount > 0 && online)
                IconButton.filled(
                  onPressed: syncing ? null : onSync,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  icon: syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : const Icon(AppIcons.sync, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),

          StatCardRow(
            children: [
              StatCard(
                icon: AppIcons.feed,
                value: AppFormats.kg(feedSummary.totalBalanceKg),
                label: 'Stok Pakan',
                color: AppColors.primary,
              ),
              StatCard(
                icon: AppIcons.livestock,
                value: AppFormats.ekor(livestockSummary.totalPopulation),
                label: 'Jumlah Ternak',
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatCardRow(
            children: [
              StatCard(
                icon: AppIcons.pending,
                value: '$_pendingCount',
                label: 'Menunggu Sync',
                color: AppColors.warning,
              ),
              StatCard(
                icon: AppIcons.synced,
                value:
                    '${records.where((r) => r.syncStatus == SyncStatus.synced).length}',
                label: 'Tersinkron',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Catat Sekarang',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _QuickActions(
            session: session,
            records: records,
            onAddRecord: onAddRecord,
            online: online,
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordsPage(
                      session: session,
                      records: records,
                      onAddRecord: onAddRecord,
                      onUpdateRecord: onUpdateRecord,
                      onDeleteRecord: onDeleteRecord,
                      onRefreshRecords: onRefreshRecords,
                    ),
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_recent.isEmpty)
            EmptyState(
              icon: AppIcons.emptyInbox,
              title: 'Belum ada catatan',
              message:
                  'Mulai catat transaksi pakan, kejadian ternak, atau laporan harian.',
            )
          else
            for (final record in _recent) ...[
              RecordTile(
                record: record,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordDetailPage(
                      session: session,
                      record: record,
                      onUpdateRecord: onUpdateRecord,
                      onDeleteRecord: onDeleteRecord,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.session,
    required this.records,
    required this.onAddRecord,
    required this.online,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final bool online;

  static const _actions = [
    (type: RecordType.feedTransaction, label: 'Pakan', icon: AppIcons.feed),
    (
      type: RecordType.livestockEvent,
      label: 'Ternak',
      icon: AppIcons.livestock,
    ),
    (
      type: RecordType.savingsTransaction,
      label: 'Simpanan',
      icon: AppIcons.savings,
    ),
    (type: RecordType.loanRepayment, label: 'Cicilan', icon: AppIcons.loan),
    (
      type: RecordType.dailyReport,
      label: 'Laporan',
      icon: AppIcons.dailyReport,
    ),
    (
      type: RecordType.sellerCredit,
      label: 'Kredit',
      icon: AppIcons.sellerCredit,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _ActionCard(
          icon: AppIcons.loanApplication,
          label: 'Pinjaman',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoanApplicationsPage(session: session, online: online),
            ),
          ),
        ),
        ..._actions.map(
          (a) => _ActionCard(
            icon: a.icon,
            label: a.label,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecordFormPage(
                  session: session,
                  recordType: a.type,
                  onSave: onAddRecord,
                  records: records,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
