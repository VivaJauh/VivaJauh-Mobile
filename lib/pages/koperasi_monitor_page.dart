import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'tenant_records_page.dart';

class KoperasiMonitorPage extends StatefulWidget {
  const KoperasiMonitorPage({required this.session, super.key});

  final AuthSession session;

  @override
  State<KoperasiMonitorPage> createState() => _KoperasiMonitorPageState();
}

class _KoperasiMonitorPageState extends State<KoperasiMonitorPage> {
  final _tenantService = const TenantService();

  List<KoperasiSummary> _summaries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summaries = await _tenantService.koperasiSummaries(widget.session);
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMembers =
        _summaries.fold<int>(0, (sum, s) => sum + s.memberCount);
    final totalSavings =
        _summaries.fold<double>(0, (sum, s) => sum + s.savingsTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Koperasi')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              EmptyState(
                icon: AppIcons.warning,
                title: 'Gagal memuat',
                message: _error!,
              )
            else ...[
              StatCardRow(
                children: [
                  StatCard(
                    icon: AppIcons.koperasi,
                    value: '${_summaries.length}',
                    label: 'Koperasi Primer',
                    color: AppColors.primary,
                  ),
                  StatCard(
                    icon: AppIcons.members,
                    value: '$totalMembers',
                    label: 'Total Anggota',
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StatCard(
                icon: AppIcons.savings,
                value: AppFormats.rupiahCompact(totalSavings),
                label: 'Total Simpanan Program',
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                'Ringkasan per Koperasi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              for (final summary in _summaries) ...[
                _KoperasiTile(
                  summary: summary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantRecordsPage(
                        session: widget.session,
                        title: summary.koperasiName,
                        subtitle:
                            'Catatan tersinkron ${summary.koperasiName}',
                        loader: () => _tenantService.tenantRecords(
                          widget.session,
                          summary.tenantId,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _KoperasiTile extends StatelessWidget {
  const _KoperasiTile({required this.summary, required this.onTap});

  final KoperasiSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Koperasi ${summary.koperasiName}, ${summary.memberCount} anggota, '
          '${summary.recordCount} catatan, simpanan ${AppFormats.rupiah(summary.savingsTotal)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AppIcons.koperasi,
                      color: AppColors.primaryDark,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.koperasiName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        if (summary.focusArea != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary.focusArea!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 14,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    label: 'Anggota',
                    value: '${summary.memberCount}',
                  ),
                  _MiniStat(
                    label: 'Catatan',
                    value: '${summary.recordCount}',
                  ),
                  _MiniStat(
                    label: 'Simpanan',
                    value: AppFormats.rupiahCompact(summary.savingsTotal),
                  ),
                  _MiniStat(
                    label: 'Cicilan',
                    value: AppFormats.rupiahCompact(summary.repaymentTotal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
