import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/loan_service.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_detail_page.dart';

typedef _SecondaryHomeData = (List<KoperasiSummary>, List<LoanApplication>);

class SecondaryHomePage extends StatelessWidget {
  const SecondaryHomePage({
    required this.session,
    required this.online,
    super.key,
  });

  final AuthSession session;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FetchBloc<_SecondaryHomeData>(() async {
        final results = await Future.wait<Object>([
          const TenantService().koperasiSummaries(
            session,
            preferCache: !online,
            allowNetwork: online,
          ),
          const LoanService().list(
            session,
            status: LoanStatus.pendingReview,
            preferCache: !online,
            allowNetwork: online,
          ),
        ]);
        return (
          results[0] as List<KoperasiSummary>,
          results[1] as List<LoanApplication>,
        );
      })..add(const FetchRequested()),
      child: _SecondaryHomeView(session: session, online: online),
    );
  }
}

class _SecondaryHomeView extends StatelessWidget {
  const _SecondaryHomeView({required this.session, required this.online});

  final AuthSession session;
  final bool online;

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<FetchBloc<_SecondaryHomeData>>();
    bloc.add(const FetchRequested());
    return bloc.stream.firstWhere(
      (state) => state.status != FetchStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FetchBloc<_SecondaryHomeData>>().state;
    final showSpinner =
        state.data == null &&
        (state.status == FetchStatus.loading ||
            state.status == FetchStatus.initial);
    final summaries = state.data?.$1 ?? const <KoperasiSummary>[];
    final pendingReview = (state.data?.$2 ?? const <LoanApplication>[])
        .where(
          (application) =>
              application.approvalRole == LoanApprovalRole.secondaryAdmin,
        )
        .toList();
    final totalMembers = summaries.fold<int>(
      0,
      (sum, s) => sum + s.memberCount,
    );
    final totalSavings = summaries.fold<double>(
      0,
      (sum, s) => sum + s.savingsTotal,
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => _refresh(context),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (!online) const OfflineBanner(online: false),
            Text(
              'Pengurus Sekunder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              session.koperasiName ?? session.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 16),
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
              StatCardRow(
                children: [
                  StatCard(
                    icon: AppIcons.savings,
                    value: AppFormats.rupiahCompact(totalSavings),
                    label: 'Simpanan Program',
                    color: AppColors.success,
                  ),
                  StatCard(
                    icon: AppIcons.pending,
                    value: '${pendingReview.length}',
                    label: 'Menunggu Review',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Antrian Keputusan (${pendingReview.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (pendingReview.isEmpty)
                const EmptyState(
                  icon: AppIcons.approve,
                  title: 'Tidak ada antrian',
                  message:
                      'Semua pengajuan pinjaman sudah diputuskan. Kerja bagus!',
                )
              else
                for (final app in pendingReview) ...[
                  _ReviewQueueTile(
                    application: app,
                    onTap: () async {
                      final bloc = context
                          .read<FetchBloc<_SecondaryHomeData>>();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoanDetailPage(
                            session: session,
                            applicationId: app.id,
                          ),
                        ),
                      );
                      if (!bloc.isClosed) bloc.add(const FetchRequested());
                    },
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

class _ReviewQueueTile extends StatelessWidget {
  const _ReviewQueueTile({required this.application, required this.onTap});

  final LoanApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = application.recommendation?.riskLevel;

    return Semantics(
      button: true,
      label:
          'Review pengajuan ${application.applicantName} ke ${application.targetKoperasi}, '
          '${AppFormats.rupiah(application.requestedAmount)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withAlpha(120)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.pending,
                  color: AppColors.warningDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppFormats.rupiahCompact(application.requestedAmount)} · ${application.targetKoperasi} · ${application.tenureMonths} bln',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (risk != null) ...[
                      const SizedBox(height: 6),
                      StatusBadge.custom(
                        label: risk.title,
                        background: switch (risk) {
                          LoanRiskLevel.low => const Color(0xFFDCF5E8),
                          LoanRiskLevel.medium => AppColors.secondaryLight,
                          LoanRiskLevel.high => const Color(0xFFFFE4E1),
                        },
                        foreground: switch (risk) {
                          LoanRiskLevel.low => AppColors.successDark,
                          LoanRiskLevel.medium => AppColors.warningDark,
                          LoanRiskLevel.high => AppColors.dangerDark,
                        },
                        icon: switch (risk) {
                          LoanRiskLevel.low => AppIcons.riskLow,
                          LoanRiskLevel.medium => AppIcons.warning,
                          LoanRiskLevel.high => AppIcons.riskHigh,
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                AppIcons.chevronRight,
                size: 14,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
