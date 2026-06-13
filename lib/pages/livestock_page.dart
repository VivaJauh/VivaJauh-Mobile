import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';

class LivestockPage extends StatefulWidget {
  const LivestockPage({
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
  State<LivestockPage> createState() => _LivestockPageState();
}

class _LivestockPageState extends State<LivestockPage> {
  LivestockEventType? _eventFilter;

  @override
  Widget build(BuildContext context) {
    final summary = Aggregator.computeLivestock(widget.records);
    final filtered = _eventFilter == null
        ? summary.history
        : summary.history
              .where(
                (r) =>
                    PayloadReader(r.payloadJson).livestockEventType ==
                    _eventFilter,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ternak')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordFormPage(
              session: widget.session,
              recordType: RecordType.livestockEvent,
              onSave: widget.onAddRecord,
              records: widget.records,
            ),
          ),
        ),
        child: const Icon(AppIcons.add),
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefreshRecords,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.livestock,
                  value: AppFormats.ekor(summary.totalPopulation),
                  label: 'Populasi',
                  color: AppColors.primary,
                ),
                StatCard(
                  icon: AppIcons.death,
                  value: AppFormats.ekor(summary.totalDeaths),
                  label: 'Kematian',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.health,
                  value: '${summary.healthNotes}',
                  label: 'Catatan Kesehatan',
                  color: AppColors.success,
                ),
                StatCard(
                  icon: AppIcons.feed,
                  value: AppFormats.kg(summary.feedUsageKg),
                  label: 'Pakan Terpakai',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (summary.populationByType.isNotEmpty) ...[
              SectionCard(
                child: HBarChart(
                  title: 'Populasi per Jenis',
                  unit: ' ekor',
                  items:
                      (summary.populationByType.entries.toList()
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

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _eventFilter == null,
                    onTap: () => setState(() => _eventFilter = null),
                  ),
                  for (final type in LivestockEventType.values)
                    _FilterChip(
                      label: type.label,
                      selected: _eventFilter == type,
                      onTap: () => setState(
                        () => _eventFilter = _eventFilter == type ? null : type,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (filtered.isEmpty)
              EmptyState(
                icon: AppIcons.emptyInbox,
                title: 'Tidak ada data',
                message: 'Belum ada catatan kejadian ternak.',
              )
            else
              ...filtered
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
                              session: widget.session,
                              record: r,
                              onUpdateRecord: widget.onUpdateRecord,
                              onDeleteRecord: widget.onDeleteRecord,
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
