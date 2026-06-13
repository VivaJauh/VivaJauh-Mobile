import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'tenant_records_page.dart';

class KoperasiMonitorPage extends StatelessWidget {
  const KoperasiMonitorPage({required this.session, super.key});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FetchBloc<List<KoperasiSummary>>(
        () => const TenantService().koperasiSummaries(session),
      )..add(const FetchRequested()),
      child: _KoperasiMonitorView(session: session),
    );
  }
}

class _KoperasiMonitorView extends StatelessWidget {
  const _KoperasiMonitorView({required this.session});

  final AuthSession session;

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<FetchBloc<List<KoperasiSummary>>>();
    bloc.add(const FetchRequested());
    return bloc.stream
        .firstWhere((state) => state.status != FetchStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FetchBloc<List<KoperasiSummary>>>().state;
    final showSpinner = state.data == null &&
        (state.status == FetchStatus.loading ||
            state.status == FetchStatus.initial);
    final summaries = state.data ?? const <KoperasiSummary>[];
    final totalMembers =
        summaries.fold<int>(0, (sum, s) => sum + s.memberCount);
    final totalSavings =
        summaries.fold<double>(0, (sum, s) => sum + s.savingsTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Koperasi')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (showSpinner)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              StatCardRow(
                children: [
                  StatCard(
                    icon: AppIcons.koperasi,
                    value: '${summaries.length}',
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
              for (final summary in summaries) ...[
                _KoperasiTile(
                  summary: summary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantRecordsPage(
                        session: session,
                        title: summary.koperasiName,
                        subtitle:
                            'Catatan tersinkron ${summary.koperasiName}',
                        loader: () => const TenantService().tenantRecords(
                          session,
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
