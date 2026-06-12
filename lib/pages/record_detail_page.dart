import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'record_form_page.dart';

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({
    required this.session,
    required this.record,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    super.key,
  });

  final AuthSession session;
  final OfflineRecord record;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;

  @override
  Widget build(BuildContext context) {
    final reader = PayloadReader(record.payloadJson);
    final color = AppRecordStyle.color(record.recordType);
    final icon = AppRecordStyle.icon(record.recordType);

    return Scaffold(
      appBar: AppBar(
        title: Text(record.recordType.title),
        actions: [
          if (record.recordType != RecordType.correction)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'correct') _pushCorrection(context);
                if (v == 'delete') _showDeleteSheet(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'correct', child: Text('Ajukan Koreksi')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Ajukan Hapus',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.recordType.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (reader.primary.isNotEmpty)
                        Text(
                          reader.primary,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge.sync(record.syncStatus),
                    const SizedBox(width: 8),
                    StatusBadge.verification(record.verificationStatus),
                  ],
                ),
                if (record.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    record.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _TimeRow(
                  icon: AppIcons.recordedAt,
                  label: 'Dicatat',
                  value: AppFormats.dateLong(record.recordedAt),
                ),
                if (record.uploadedAt != null) ...[
                  const SizedBox(height: 8),
                  _TimeRow(
                    icon: AppIcons.synced,
                    label: 'Diunggah',
                    value: AppFormats.dateLong(record.uploadedAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ..._buildDetailRows(context, reader),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (record.recordType != RecordType.correction) ...[
            OutlinedButton.icon(
              onPressed: () => _pushCorrection(context),
              icon: const Icon(AppIcons.correction, size: 18),
              label: const Text('Ajukan Koreksi'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showDeleteSheet(context),
              icon: const Icon(AppIcons.delete, size: 18),
              label: const Text('Ajukan Hapus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows(BuildContext context, PayloadReader r) {
    final rows = <({String label, String value})>[];

    switch (record.recordType) {
      case RecordType.feedTransaction:
        rows.addAll([
          (label: 'Jenis Pakan', value: r.primary),
          (label: 'Arah', value: r.feedDirection.label),
          (label: 'Jumlah', value: AppFormats.kg(r.quantity.toDouble())),
          if (r.warehouse.isNotEmpty) (label: 'Gudang', value: r.warehouse),
        ]);
      case RecordType.livestockEvent:
        rows.addAll([
          (label: 'Jenis Ternak', value: r.primary),
          (label: 'Kejadian', value: r.livestockEventType.label),
          (label: 'Jumlah', value: r.livestockEventType.quantityIsKg
              ? AppFormats.kg(r.quantity.toDouble())
              : AppFormats.ekor(r.quantity.toDouble())),
          if (r.pen.isNotEmpty) (label: 'Kandang', value: r.pen),
          if (r.healthNote.isNotEmpty) (label: 'Catatan Kesehatan', value: r.healthNote),
        ]);
      case RecordType.savingsTransaction:
        rows.addAll([
          (label: 'Anggota', value: r.primary),
          (label: 'Jenis', value: r.savingsDirection.label),
          (label: 'Jumlah', value: AppFormats.rupiah(r.quantity.toDouble())),
          if (r.memberId.isNotEmpty) (label: 'ID Anggota', value: r.memberId),
        ]);
      case RecordType.loanRepayment:
        rows.addAll([
          (label: 'Anggota', value: r.primary),
          (label: 'Jumlah Cicilan', value: AppFormats.rupiah(r.quantity.toDouble())),
          if (r.loanRef.isNotEmpty) (label: 'Referensi', value: r.loanRef),
        ]);
      case RecordType.dailyReport:
        rows.addAll([
          (label: 'Ringkasan', value: r.primary),
          if (r.issues.isNotEmpty) (label: 'Kendala', value: r.issues),
        ]);
      case RecordType.sellerCredit:
        rows.addAll([
          (label: 'Penjual', value: r.primary),
          (label: 'Jumlah', value: AppFormats.rupiah(r.quantity.toDouble())),
          if (r.items.isNotEmpty) (label: 'Barang', value: r.items),
        ]);
      case RecordType.correction:
        rows.add((label: 'Alasan', value: r.primary));
    }

    if (r.note.isNotEmpty) rows.add((label: 'Catatan', value: r.note));
    if (r.officer.isNotEmpty) rows.add((label: 'Petugas', value: r.officer));

    return rows
        .map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.label,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  void _pushCorrection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormPage(
          session: session,
          initialRecord: record,
          onSave: onUpdateRecord,
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(AppIcons.delete, color: AppColors.danger, size: 32),
              const SizedBox(height: 12),
              Text(
                'Ajukan Penghapusan',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Penghapusan akan diajukan sebagai koreksi dan perlu diverifikasi admin.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await onDeleteRecord(record);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Ajukan Hapus'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
