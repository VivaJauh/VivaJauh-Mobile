import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/loan_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';

class LoanDetailPage extends StatelessWidget {
  const LoanDetailPage({
    required this.session,
    required this.applicationId,
    super.key,
  });

  final AuthSession session;
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoanDetailBloc(
        loanService: const LoanService(),
        session: session,
        applicationId: applicationId,
      )..add(const LoanDetailRequested()),
      child: _LoanDetailView(session: session),
    );
  }
}

class _LoanDetailView extends StatelessWidget {
  const _LoanDetailView({required this.session});

  final AuthSession session;

  bool get _isSecondaryAdmin => session.role == 'secondary_admin';

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<LoanDetailBloc>();
    bloc.add(const LoanDetailRequested());
    return bloc.stream.firstWhere((state) => !state.loading);
  }

  Future<void> _decide(BuildContext context, {required bool approve}) async {
    final bloc = context.read<LoanDetailBloc>();
    final note = await _askReviewNote(context, approve: approve);
    if (note == null || bloc.isClosed) return;
    bloc.add(LoanDecisionSubmitted(approve: approve, note: note));
  }

  Future<String?> _askReviewNote(
    BuildContext context, {
    required bool approve,
  }) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _ReviewNoteSheet(
          approve: approve,
          controller: controller,
          onSubmit: (value) => Navigator.pop(sheetContext, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LoanDetailBloc>().state;
    final app = state.application;

    return BlocListener<LoanDetailBloc, LoanDetailState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) {
        final notice = state.notice!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor:
                notice.isError ? AppColors.danger : AppColors.success,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail Pengajuan')),
        body: state.loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    if (state.analyzing) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Menganalisis riwayat lintas koperasi…',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : state.error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyState(
                      icon: AppIcons.warning,
                      title: 'Gagal memuat',
                      message: state.error!,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        _ApplicationCard(application: app!),
                        const SizedBox(height: 12),
                        if (app.recommendation != null) ...[
                          _RecommendationCard(
                            recommendation: app.recommendation!,
                          ),
                          const SizedBox(height: 12),
                          _KeyStatsSection(
                            keyStats: app.recommendation!.keyStats,
                          ),
                          const SizedBox(height: 12),
                          if (app.recommendation!.evidence.isNotEmpty) ...[
                            _EvidenceSection(
                              evidence: app.recommendation!.evidence,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                        if (app.status == LoanStatus.pendingReview &&
                            _isSecondaryAdmin)
                          _DecisionButtons(
                            deciding: state.deciding,
                            onApprove: () =>
                                _decide(context, approve: true),
                            onReject: () =>
                                _decide(context, approve: false),
                          )
                        else if (app.status != LoanStatus.pendingReview)
                          _DecisionResultCard(application: app)
                        else
                          const _AwaitingAdminCard(),
                        if (state.trail != null) ...[
                          const SizedBox(height: 12),
                          _AuditTrailSection(trail: state.trail!),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final LoanApplication application;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.loanApplication,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    if (application.applicantMemberId != null)
                      Text(
                        'ID: ${application.applicantMemberId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: AppIcons.koperasi,
            label: 'Koperasi tujuan',
            value: application.targetKoperasi,
          ),
          _InfoRow(
            icon: AppIcons.savings,
            label: 'Jumlah pinjaman',
            value: AppFormats.rupiah(application.requestedAmount),
          ),
          _InfoRow(
            icon: AppIcons.tenure,
            label: 'Tenor',
            value: '${application.tenureMonths} bulan',
          ),
          if (application.purpose != null)
            _InfoRow(
              icon: AppIcons.purpose,
              label: 'Tujuan',
              value: application.purpose!,
            ),
          _InfoRow(
            icon: AppIcons.recordedAt,
            label: 'Diajukan',
            value: AppFormats.dateLong(application.createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final LoanRecommendation recommendation;

  Color get _color => switch (recommendation.riskLevel) {
        LoanRiskLevel.low => AppColors.success,
        LoanRiskLevel.medium => AppColors.warning,
        LoanRiskLevel.high => AppColors.danger,
      };

  Color get _darkColor => switch (recommendation.riskLevel) {
        LoanRiskLevel.low => AppColors.successDark,
        LoanRiskLevel.medium => AppColors.warningDark,
        LoanRiskLevel.high => AppColors.dangerDark,
      };

  IconData get _icon => switch (recommendation.riskLevel) {
        LoanRiskLevel.low => AppIcons.riskLow,
        LoanRiskLevel.medium => AppIcons.warning,
        LoanRiskLevel.high => AppIcons.riskHigh,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 22, color: _darkColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.riskLevel.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
              ),
              StatusBadge.custom(
                label: recommendation.fromAi ? 'Analisis AI' : 'Analisis Sistem',
                background: AppColors.surface,
                foreground: AppColors.primaryDark,
                icon: AppIcons.ai,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.recommendationTitle,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyStatsSection extends StatelessWidget {
  const _KeyStatsSection({required this.keyStats});

  final Map<String, dynamic> keyStats;

  num _stat(String key) => keyStats[key] as num? ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StatCardRow(
          children: [
            StatCard(
              icon: AppIcons.koperasi,
              value: '${_stat('known_cooperatives')}',
              label: 'Koperasi Terdata',
              color: AppColors.primary,
            ),
            StatCard(
              icon: AppIcons.verified,
              value: '${_stat('good_history_count')}',
              label: 'Riwayat Baik',
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 8),
        StatCardRow(
          children: [
            StatCard(
              icon: AppIcons.warning,
              value: '${_stat('arrears_cooperative_count')}',
              label: 'Ada Tunggakan',
              color: AppColors.warning,
            ),
            StatCard(
              icon: AppIcons.delay,
              value: '${_stat('late_payment_count')}',
              label: 'Keterlambatan',
              color: AppColors.danger,
            ),
          ],
        ),
      ],
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.evidence});

  final List<LoanEvidence> evidence;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temuan Riwayat',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          for (final item in evidence) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.status == 'good_history'
                      ? AppIcons.verified
                      : AppIcons.warning,
                  size: 16,
                  color: item.status == 'good_history'
                      ? AppColors.successDark
                      : AppColors.warningDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.koperasi,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.finding,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item != evidence.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons({
    required this.deciding,
    required this.onApprove,
    required this.onReject,
  });

  final bool deciding;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: deciding ? null : onReject,
              icon: const Icon(AppIcons.reject, size: 18),
              label: const Text('Tolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerDark,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: deciding ? null : onApprove,
              icon: const Icon(AppIcons.approve, size: 18),
              label: const Text('Setujui'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AwaitingAdminCard extends StatelessWidget {
  const _AwaitingAdminCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.pending,
            size: 18,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Menunggu keputusan Pengurus Sekunder. Koperasi sekunder berwenang menyetujui atau menolak setelah melihat rekap 12 bulan terakhir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionResultCard extends StatelessWidget {
  const _DecisionResultCard({required this.application});

  final LoanApplication application;

  bool get _approved => application.status == LoanStatus.approved;

  @override
  Widget build(BuildContext context) {
    final color = _approved ? AppColors.success : AppColors.danger;
    final darkColor = _approved ? AppColors.successDark : AppColors.dangerDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _approved ? AppIcons.approve : AppIcons.reject,
                size: 20,
                color: darkColor,
              ),
              const SizedBox(width: 8),
              Text(
                application.status.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: darkColor,
                ),
              ),
            ],
          ),
          if (application.reviewNote != null &&
              application.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${application.reviewNote}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          if (application.reviewedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Diputuskan ${AppFormats.dateLong(application.reviewedAt!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewNoteSheet extends StatefulWidget {
  const _ReviewNoteSheet({
    required this.approve,
    required this.controller,
    required this.onSubmit,
  });

  final bool approve;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  State<_ReviewNoteSheet> createState() => _ReviewNoteSheetState();
}

class _ReviewNoteSheetState extends State<_ReviewNoteSheet> {
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    final color = widget.approve ? AppColors.success : AppColors.danger;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.approve ? 'Setujui Pengajuan' : 'Tolak Pengajuan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Catatan keputusan wajib diisi dan akan tercatat permanen di jejak audit.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.approve
                ? 'Contoh: Riwayat baik, disetujui dengan plafon penuh'
                : 'Contoh: Selesaikan tunggakan di koperasi asal dahulu',
            errorText: _validationError,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              final note = widget.controller.text.trim();
              if (note.isEmpty) {
                setState(
                  () => _validationError = 'Catatan keputusan wajib diisi',
                );
                return;
              }
              widget.onSubmit(note);
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(
              widget.approve ? 'Konfirmasi Setujui' : 'Konfirmasi Tolak',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ),
      ],
    );
  }
}

class _AuditTrailSection extends StatelessWidget {
  const _AuditTrailSection({required this.trail});

  final LoanAuditTrail trail;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jejak Audit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusBadge.custom(
                label: trail.integrityValid
                    ? 'Rantai Valid (${trail.checkedEntries})'
                    : 'Integritas Rusak',
                background: trail.integrityValid
                    ? const Color(0xFFDCF5E8)
                    : const Color(0xFFFFE4E1),
                foreground: trail.integrityValid
                    ? AppColors.successDark
                    : AppColors.dangerDark,
                icon: trail.integrityValid ? AppIcons.riskLow : AppIcons.riskHigh,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Append-only, setiap entri terikat hash SHA-256 ke entri sebelumnya.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(height: 12),
          if (trail.flags.isEmpty)
            Row(
              children: [
                const Icon(
                  AppIcons.verified,
                  size: 15,
                  color: AppColors.successDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tidak ada penanda mencurigakan.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: trail.flags
                  .map(
                    (flag) => StatusBadge.custom(
                      label: loanFlagTitle(flag),
                      background: const Color(0xFFFFF0C0),
                      foreground: AppColors.warningDark,
                      icon: AppIcons.warning,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 14),
          for (final entry in trail.timeline)
            _AuditTimelineEntry(
              entry: entry,
              isLast: entry == trail.timeline.last,
            ),
        ],
      ),
    );
  }
}

Color _auditActionColor(String action) => switch (action) {
      'loan_application_approved' => AppColors.success,
      'loan_application_rejected' => AppColors.danger,
      'loan_recommendation_generated' => AppColors.secondary,
      'loan_audit_report_exported' => AppColors.muted,
      _ => AppColors.primary,
    };

Color _auditActionDarkColor(String action) => switch (action) {
      'loan_application_approved' => AppColors.successDark,
      'loan_application_rejected' => AppColors.dangerDark,
      'loan_recommendation_generated' => AppColors.warningDark,
      'loan_audit_report_exported' => AppColors.muted,
      _ => AppColors.primaryDark,
    };

IconData _auditActionIcon(String action) => switch (action) {
      'loan_application_created' => AppIcons.add,
      'loan_recommendation_generated' => AppIcons.ai,
      'loan_application_approved' => AppIcons.approve,
      'loan_application_rejected' => AppIcons.reject,
      'loan_audit_report_exported' => AppIcons.export,
      _ => AppIcons.records,
    };

class _AuditTimelineEntry extends StatelessWidget {
  const _AuditTimelineEntry({required this.entry, required this.isLast});

  final LoanAuditEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _auditActionColor(entry.action);
    final darkColor = _auditActionDarkColor(entry.action);

    return Semantics(
      button: true,
      label:
          '${entry.actionTitle} oleh ${entry.actorName}, ketuk untuk detail',
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withAlpha(28),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: color.withAlpha(90)),
                    ),
                    child: Icon(
                      _auditActionIcon(entry.action),
                      size: 14,
                      color: darkColor,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.actionTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: darkColor,
                              ),
                            ),
                          ),
                          Text(
                            AppFormats.time(entry.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            AppIcons.chevronRight,
                            size: 11,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.actorName} · ${roleTitleOf(entry.actorRole)} · ${AppFormats.dateShort(entry.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.reviewNote != null &&
                          entry.reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${entry.reviewNote}"',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: _AuditEntryDetailSheet(entry: entry),
        ),
      ),
    );
  }
}

class _AuditEntryDetailSheet extends StatelessWidget {
  const _AuditEntryDetailSheet({required this.entry});

  final LoanAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final darkColor = _auditActionDarkColor(entry.action);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _auditActionColor(entry.action).withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _auditActionIcon(entry.action),
                size: 19,
                color: darkColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.actionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: darkColor,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailRow(label: 'Pelaku', value: entry.actorName),
        _DetailRow(label: 'Peran', value: roleTitleOf(entry.actorRole)),
        _DetailRow(
          label: 'Waktu',
          value:
              '${AppFormats.dateLong(entry.createdAt)} · ${AppFormats.time(entry.createdAt)} WIB',
        ),
        if (entry.resultStatus.isNotEmpty)
          _DetailRow(label: 'Hasil', value: entry.resultStatus),
        if (entry.riskLevel != null)
          _DetailRow(
            label: 'Tingkat risiko',
            value: LoanRiskLevelX.fromApiValue(entry.riskLevel).title,
          ),
        if (entry.reviewNote != null && entry.reviewNote!.isNotEmpty)
          _DetailRow(label: 'Catatan', value: entry.reviewNote!),
        if (entry.reportHash != null)
          _DetailRow(
            label: 'Hash laporan',
            value: entry.reportHash!,
            monospace: true,
          ),
        if (entry.selfHash != null) ...[
          const Divider(height: 24, color: AppColors.border),
          Text(
            'Sidik Jari Entri (SHA-256)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              entry.selfHash!,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Entri ini terikat secara kriptografis ke entri sebelumnya. '
            'Perubahan sekecil apa pun akan merusak rantai dan terdeteksi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
