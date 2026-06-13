import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/loan_service.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_apply_page.dart';
import 'loan_detail_page.dart';
import 'tenant_records_page.dart';

class _LoanApplicationsData {
  const _LoanApplicationsData({
    required this.applications,
    this.repaymentMembers = const [],
  });

  final List<LoanApplication> applications;
  final List<MemberSummary> repaymentMembers;
}

class LoanApplicationsPage extends StatelessWidget {
  const LoanApplicationsPage({
    required this.session,
    required this.online,
    required this.onAddRecord,
    super.key,
  });

  final AuthSession session;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FetchBloc<_LoanApplicationsData>(() async {
        final applications = await const LoanService().list(session);
        if (session.role != 'primary_admin') {
          return _LoanApplicationsData(applications: applications);
        }

        List<MemberSummary> members;
        try {
          members = await const TenantService().members(session);
        } catch (_) {
          return _LoanApplicationsData(applications: applications);
        }
        final repaymentMembers =
            members
                .where(
                  (member) =>
                      member.role == 'member' && member.repaymentTotal > 0,
                )
                .toList()
              ..sort((a, b) => b.repaymentTotal.compareTo(a.repaymentTotal));

        return _LoanApplicationsData(
          applications: applications,
          repaymentMembers: repaymentMembers,
        );
      })..add(const FetchRequested()),
      child: _LoanApplicationsView(
        session: session,
        online: online,
        onAddRecord: onAddRecord,
      ),
    );
  }
}

class _LoanApplicationsView extends StatefulWidget {
  const _LoanApplicationsView({
    required this.session,
    required this.online,
    required this.onAddRecord,
  });

  final AuthSession session;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;

  @override
  State<_LoanApplicationsView> createState() => _LoanApplicationsViewState();
}

class _LoanApplicationsViewState extends State<_LoanApplicationsView> {
  LoanStatus? _statusFilter;

  Future<void> _refresh() {
    final bloc = context.read<FetchBloc<_LoanApplicationsData>>();
    bloc.add(const FetchRequested());
    return bloc.stream.firstWhere(
      (state) => state.status != FetchStatus.loading,
    );
  }

  bool get _canApply =>
      widget.session.role == 'member' || widget.session.role == 'primary_admin';

  Future<void> _openApply() async {
    final result = await Navigator.push<LoanApplyResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LoanApplyPage(
          session: widget.session,
          online: widget.online,
          onSaveOffline: widget.onAddRecord,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.queued) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan disimpan di antrean sinkronisasi'),
        ),
      );
      return;
    }
    final created = result.created;
    if (created == null) return;
    await _refresh();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoanDetailPage(session: widget.session, applicationId: created.id),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _openDetail(LoanApplication app) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoanDetailPage(session: widget.session, applicationId: app.id),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FetchBloc<_LoanApplicationsData>>().state;
    final showSpinner =
        state.data == null &&
        (state.status == FetchStatus.loading ||
            state.status == FetchStatus.initial);
    final data =
        state.data ??
        const _LoanApplicationsData(applications: <LoanApplication>[]);
    final items = data.applications;
    final repaymentMembers = data.repaymentMembers;
    final filtered = _statusFilter == null
        ? items
        : items.where((a) => a.status == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Pinjaman'),
        actions: [
          IconButton(
            onPressed: showSpinner ? null : _refresh,
            tooltip: 'Muat ulang daftar',
            icon: const Icon(AppIcons.refresh, size: 20),
          ),
        ],
      ),
      floatingActionButton: _canApply
          ? FloatingActionButton(
              onPressed: _openApply,
              tooltip: 'Ajukan pinjaman baru',
              child: const Icon(AppIcons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            if (!widget.online)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: OfflineBanner(online: false),
              ),
            _StatusFilterChips(
              selected: _statusFilter,
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(height: 12),
            if (showSpinner)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filtered.isEmpty)
              const EmptyState(
                icon: AppIcons.loanApplication,
                title: 'Belum ada pengajuan',
                message:
                    'Belum ada pengajuan pinjaman baru. Riwayat cicilan anggota tampil di bawah jika tersedia.',
              )
            else
              for (final app in filtered) ...[
                _LoanTile(application: app, onTap: () => _openDetail(app)),
                const SizedBox(height: 8),
              ],
            if (repaymentMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RepaymentMembersSection(
                session: widget.session,
                members: repaymentMembers,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepaymentMembersSection extends StatelessWidget {
  const _RepaymentMembersSection({
    required this.session,
    required this.members,
  });

  final AuthSession session;
  final List<MemberSummary> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Cicilan Anggota',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final member in members) ...[
          _RepaymentMemberTile(session: session, member: member),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RepaymentMemberTile extends StatelessWidget {
  const _RepaymentMemberTile({required this.session, required this.member});

  final AuthSession session;
  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Riwayat cicilan ${member.name}, total ${AppFormats.rupiah(member.repaymentTotal)}',
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TenantRecordsPage(
              session: session,
              title: 'Cicilan ${member.name}',
              subtitle: 'Riwayat cicilan tersinkron milik ${member.name}',
              loader: () async {
                final records = await const TenantService().memberRecords(
                  session,
                  member.userId,
                );
                return records
                    .where(
                      (record) => record.recordType == RecordType.loanRepayment,
                    )
                    .toList();
              },
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
                  AppIcons.loan,
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
                      member.name,
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
                      '${member.recordCount} catatan tersinkron',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppFormats.rupiahCompact(member.repaymentTotal),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
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

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onChanged});

  final LoanStatus? selected;
  final ValueChanged<LoanStatus?> onChanged;

  static const _options = [
    (status: null, label: 'Semua'),
    (status: LoanStatus.pendingReview, label: 'Menunggu Review'),
    (status: LoanStatus.approved, label: 'Disetujui'),
    (status: LoanStatus.rejected, label: 'Ditolak'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _options[index];
          final active = option.status == selected;
          return ChoiceChip(
            label: Text(option.label),
            selected: active,
            onSelected: (_) => onChanged(option.status),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.text,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.border,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.application, required this.onTap});

  final LoanApplication application;
  final VoidCallback onTap;

  StatusBadge get _statusBadge => switch (application.status) {
    LoanStatus.approved => StatusBadge.custom(
      label: application.status.title,
      background: const Color(0xFFDCF5E8),
      foreground: AppColors.successDark,
      icon: AppIcons.approve,
    ),
    LoanStatus.rejected => StatusBadge.custom(
      label: application.status.title,
      background: const Color(0xFFFFE4E1),
      foreground: AppColors.dangerDark,
      icon: AppIcons.reject,
    ),
    _ => StatusBadge.custom(
      label: application.status.title,
      background: AppColors.secondaryLight,
      foreground: AppColors.warningDark,
      icon: AppIcons.pending,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Pengajuan ${application.applicantName} ke ${application.targetKoperasi}, '
          '${AppFormats.rupiah(application.requestedAmount)}, ${application.status.title}',
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
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.loanApplication,
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
                      '${application.targetKoperasi} · ${application.tenureMonths} bulan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _statusBadge,
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormats.rupiahCompact(application.requestedAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormats.dateShort(application.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
