import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/loan_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_apply_page.dart';
import 'loan_detail_page.dart';

class LoanApplicationsPage extends StatefulWidget {
  const LoanApplicationsPage({
    required this.session,
    required this.online,
    super.key,
  });

  final AuthSession session;
  final bool online;

  @override
  State<LoanApplicationsPage> createState() => _LoanApplicationsPageState();
}

class _LoanApplicationsPageState extends State<LoanApplicationsPage> {
  final _loanService = const LoanService();

  List<LoanApplication> _items = [];
  LoanStatus? _statusFilter;
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
      final items = await _loanService.list(widget.session);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<LoanApplication> get _filtered => _statusFilter == null
      ? _items
      : _items.where((a) => a.status == _statusFilter).toList();

  bool get _canApply => widget.session.role == 'member';

  Future<void> _openApply() async {
    final created = await Navigator.push<LoanApplication>(
      context,
      MaterialPageRoute(
        builder: (_) => LoanApplyPage(session: widget.session),
      ),
    );
    if (created == null || !mounted) return;
    await _load();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailPage(
          session: widget.session,
          applicationId: created.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openDetail(LoanApplication app) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanDetailPage(
          session: widget.session,
          applicationId: app.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Pinjaman'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Muat ulang daftar',
            icon: const Icon(AppIcons.refresh, size: 20),
          ),
        ],
      ),
      floatingActionButton: _canApply
          ? FloatingActionButton(
              onPressed: widget.online ? _openApply : null,
              tooltip: 'Ajukan pinjaman baru',
              child: const Icon(AppIcons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
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
            else if (_filtered.isEmpty)
              const EmptyState(
                icon: AppIcons.loanApplication,
                title: 'Belum ada pengajuan',
                message: 'Belum ada pengajuan pinjaman yang perlu ditinjau.',
              )
            else
              for (final app in _filtered) ...[
                _LoanTile(application: app, onTap: () => _openDetail(app)),
                const SizedBox(height: 8),
              ],
          ],
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
