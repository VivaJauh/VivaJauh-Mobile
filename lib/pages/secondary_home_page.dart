import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/loan_service.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_detail_page.dart';

class SecondaryHomePage extends StatefulWidget {
  const SecondaryHomePage({
    required this.session,
    required this.online,
    super.key,
  });

  final AuthSession session;
  final bool online;

  @override
  State<SecondaryHomePage> createState() => _SecondaryHomePageState();
}

class _SecondaryHomePageState extends State<SecondaryHomePage> {
  final _tenantService = const TenantService();
  final _loanService = const LoanService();

  List<KoperasiSummary> _summaries = [];
  List<LoanApplication> _pendingReview = [];
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
      final results = await Future.wait([
        _tenantService.koperasiSummaries(widget.session),
        _loanService.list(widget.session, status: LoanStatus.pendingReview),
      ]);
      if (!mounted) return;
      setState(() {
        _summaries = results[0] as List<KoperasiSummary>;
        _pendingReview = results[1] as List<LoanApplication>;
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

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!widget.online) const OfflineBanner(online: false),
          Text(
            'Pengurus Sekunder',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            widget.session.koperasiName ?? widget.session.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 16),
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
                  value: '${_pendingReview.length}',
                  label: 'Menunggu Review',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Antrian Keputusan (${_pendingReview.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (_pendingReview.isEmpty)
              const EmptyState(
                icon: AppIcons.approve,
                title: 'Tidak ada antrian',
                message:
                    'Semua pengajuan pinjaman sudah diputuskan. Kerja bagus!',
              )
            else
              for (final app in _pendingReview) ...[
                _ReviewQueueTile(
                  application: app,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoanDetailPage(
                          session: widget.session,
                          applicationId: app.id,
                        ),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
                const SizedBox(height: 8),
              ],
          ],
        ],
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
