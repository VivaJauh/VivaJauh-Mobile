import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';
import 'record_type_picker.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    required this.session,
    required this.records,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    required this.onRefreshRecords,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;
  final Future<void> Function() onRefreshRecords;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _query = '';
  RecordType? _filter;

  List<OfflineRecord> get _filtered {
    var list = widget.records.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (_filter != null) list = list.where((r) => r.recordType == _filter).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((r) =>
              r.recordType.title.toLowerCase().contains(q) ||
              (r.payloadJson[PayloadKeys.primary] as String? ?? '').toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _pushDetail(OfflineRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailPage(
          session: widget.session,
          record: record,
          onUpdateRecord: widget.onUpdateRecord,
          onDeleteRecord: widget.onDeleteRecord,
        ),
      ),
    );
  }

  Future<void> _addNew() async {
    final type = await showRecordTypePicker(context);
    if (type == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormPage(
          session: widget.session,
          recordType: type,
          onSave: widget.onAddRecord,
          records: widget.records,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Catatan')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNew,
        child: const Icon(AppIcons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: const Icon(AppIcons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(AppIcons.close, size: 16),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final type in RecordType.values)
                  if (type != RecordType.correction)
                    _FilterChip(
                      label: type.title,
                      selected: _filter == type,
                      onTap: () => setState(
                        () => _filter = _filter == type ? null : type,
                      ),
                    ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: AppIcons.emptyInbox,
                      title: 'Tidak ada catatan',
                      message: _query.isNotEmpty || _filter != null
                          ? 'Tidak ditemukan catatan yang cocok.'
                          : 'Belum ada catatan. Tap + untuk menambah.',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: widget.onRefreshRecords,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => RecordTile(
                        record: records[i],
                        onTap: () => _pushDetail(records[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
