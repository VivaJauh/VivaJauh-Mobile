import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';

class SyncQueuePage extends StatelessWidget {
  const SyncQueuePage({
    required this.records,
    required this.syncing,
    required this.online,
    required this.onSync,
    required this.onRetryRecord,
    super.key,
  });

  final List<OfflineRecord> records;
  final bool syncing;
  final bool online;
  final Future<void> Function() onSync;
  final Future<void> Function(OfflineRecord) onRetryRecord;

  List<OfflineRecord> get _pending =>
      records.where((r) => r.syncStatus == SyncStatus.pending).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  List<OfflineRecord> get _failed =>
      records.where((r) => r.syncStatus == SyncStatus.failed).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  List<OfflineRecord> get _conflict =>
      records.where((r) => r.syncStatus == SyncStatus.conflict).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final failed = _failed;
    final conflict = _conflict;
    final synced = records.where((r) => r.syncStatus == SyncStatus.synced).length;
    final needsAction = pending.length + failed.length + conflict.length;
    final delay = Aggregator.computeSyncDelays(records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinkronisasi'),
        actions: [
          if (needsAction > 0 && online)
            TextButton.icon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.sync, size: 18),
              label: const Text('Sinkronkan'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCardRow(
            children: [
              StatCard(
                icon: AppIcons.pending,
                value: '${pending.length}',
                label: 'Menunggu',
                color: AppColors.warning,
              ),
              StatCard(
                icon: AppIcons.failed,
                value: '${failed.length}',
                label: 'Gagal',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatCardRow(
            children: [
              StatCard(
                icon: AppIcons.conflict,
                value: '${conflict.length}',
                label: 'Konflik',
                color: AppColors.secondary,
              ),
              StatCard(
                icon: AppIcons.synced,
                value: '$synced',
                label: 'Tersinkron',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (needsAction == 0) ...[
            EmptyState(
              icon: AppIcons.synced,
              title: 'Semua tersinkronisasi',
              message: 'Tidak ada catatan yang menunggu sinkronisasi.',
            ),
          ] else ...[
            if (failed.isNotEmpty) ...[
              _SectionHeader(
                label: 'Gagal (${failed.length})',
                color: AppColors.danger,
              ),
              const SizedBox(height: 8),
              ...failed.map(
                (r) => _SyncTile(
                  record: r,
                  onRetry: () => onRetryRecord(r),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (conflict.isNotEmpty) ...[
              _SectionHeader(
                label: 'Konflik (${conflict.length})',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 8),
              ...conflict.map(
                (r) => _SyncTile(record: r, onRetry: () => onRetryRecord(r)),
              ),
              const SizedBox(height: 16),
            ],

            if (pending.isNotEmpty) ...[
              _SectionHeader(
                label: 'Menunggu (${pending.length})',
                color: AppColors.warning,
              ),
              const SizedBox(height: 8),
              ...pending.map((r) => _SyncTile(record: r)),
              const SizedBox(height: 16),
            ],
          ],

          if (delay.entries.isNotEmpty) ...[
            Text(
              'Audit Delay Sinkronisasi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rata-rata: ${AppFormats.delta(delay.averageDelay)} · Maks: ${AppFormats.delta(delay.maxDelay)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            ...delay.entries.take(10).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(AppIcons.delay, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.record.recordType.title,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormats.delta(entry.delay),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SyncTile extends StatelessWidget {
  const _SyncTile({required this.record, this.onRetry});

  final OfflineRecord record;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = record.syncStatus == SyncStatus.failed ||
        record.syncStatus == SyncStatus.conflict;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed ? AppColors.danger.withAlpha(80) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          StatusBadge.sync(record.syncStatus),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.recordType.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AppFormats.dateShort(record.recordedAt),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                if (record.errorMessage != null &&
                    record.errorMessage!.isNotEmpty)
                  Text(
                    record.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(AppIcons.sync, size: 18),
              color: AppColors.primary,
              tooltip: 'Coba lagi',
            ),
        ],
      ),
    );
  }
}
