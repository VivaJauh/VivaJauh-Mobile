import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/fund_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';

class FundPage extends StatelessWidget {
  const FundPage({required this.session, required this.online, super.key});

  final AuthSession session;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FundBloc(fundService: const FundService(), session: session)
            ..add(const FundOverviewRequested()),
      child: _FundView(session: session, online: online),
    );
  }
}

class _FundView extends StatelessWidget {
  const _FundView({required this.session, required this.online});

  final AuthSession session;
  final bool online;

  bool get _canRecord => session.role == 'primary_admin';

  String get _title => switch (session.role) {
    'primary_admin' => 'Dana Anggota',
    'secondary_admin' => 'Monitoring Dana',
    _ => 'Dana Saya',
  };

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<FundBloc>();
    bloc.add(const FundOverviewRequested());
    return bloc.stream.firstWhere((state) => !state.loading);
  }

  Future<void> _recordPayment(BuildContext context, FundItem item) async {
    final bloc = context.read<FundBloc>();
    final result = await showModalBottomSheet<_PaymentInput>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSheet(item: item),
    );
    if (result == null || bloc.isClosed) return;

    bloc.add(
      FundPaymentSubmitted(
        memberId: item.memberId,
        fundType: item.fundType,
        periodKey: item.periodKey,
        amount: result.amount,
        note: result.note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FundBloc>().state;
    final loading = state.loading;
    final error = state.error;
    final overview = state.overview;

    return BlocListener<FundBloc, FundState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) {
        final notice = state.notice!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor: notice.isError
                ? AppColors.danger
                : AppColors.success,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              onPressed: loading ? null : () => _refresh(context),
              tooltip: 'Muat ulang dana',
              icon: const Icon(AppIcons.refresh, size: 20),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _refresh(context),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (!online)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: OfflineBanner(online: false),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (error != null)
                EmptyState(
                  icon: AppIcons.warning,
                  title: 'Gagal memuat',
                  message: error,
                )
              else if (overview == null)
                const EmptyState(
                  icon: AppIcons.savings,
                  title: 'Belum ada data',
                  message: 'Data dana akan muncul setelah sinkronisasi.',
                )
              else ...[
                _DueInfoCard(overview: overview),
                const SizedBox(height: 12),
                StatCardRow(
                  children: [
                    StatCard(
                      icon: AppIcons.members,
                      value: '${overview.totals.memberCount}',
                      label: session.role == 'member' ? 'Akun' : 'Anggota',
                      color: AppColors.primary,
                    ),
                    StatCard(
                      icon: AppIcons.savings,
                      value: AppFormats.rupiahCompact(
                        overview.totals.paidTotal,
                      ),
                      label: 'Terbayar',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatCardRow(
                  children: [
                    StatCard(
                      icon: AppIcons.pending,
                      value: AppFormats.rupiahCompact(
                        overview.totals.outstandingTotal,
                      ),
                      label: 'Belum Lunas',
                      color: AppColors.warning,
                    ),
                    StatCard(
                      icon: AppIcons.warning,
                      value: AppFormats.rupiahCompact(
                        overview.totals.overdueTotal,
                      ),
                      label: 'Lewat Tempo',
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  session.role == 'member'
                      ? 'Kewajiban Saya'
                      : 'Daftar Kewajiban',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (overview.items.isEmpty)
                  const EmptyState(
                    icon: AppIcons.savings,
                    title: 'Belum ada kewajiban',
                    message: 'Dana pokok dan iuran akan dibuat otomatis.',
                  )
                else
                  for (final item in overview.items) ...[
                    _FundTile(
                      item: item,
                      showTenant: session.role == 'secondary_admin',
                      canRecord: _canRecord && item.hasOutstanding && online,
                      onRecord: () => _recordPayment(context, item),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DueInfoCard extends StatelessWidget {
  const _DueInfoCard({required this.overview});

  final FundOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.savings, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dana pokok dibayar sekali saat menjadi anggota. Dana iuran '
              '${AppFormats.rupiah(overview.monthlyDuesAmount)} jatuh tempo '
              'setiap tanggal 1, periode ${overview.currentPeriod}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
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

class _FundTile extends StatelessWidget {
  const _FundTile({
    required this.item,
    required this.showTenant,
    required this.canRecord,
    required this.onRecord,
  });

  final FundItem item;
  final bool showTenant;
  final bool canRecord;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      FundPaymentStatus.paid => AppColors.successDark,
      FundPaymentStatus.partial => AppColors.warningDark,
      FundPaymentStatus.overdue => AppColors.dangerDark,
      FundPaymentStatus.unpaid => AppColors.warningDark,
    };
    final background = switch (item.status) {
      FundPaymentStatus.paid => const Color(0xFFDCF5E8),
      FundPaymentStatus.overdue => const Color(0xFFFFE4E1),
      _ => AppColors.secondaryLight,
    };
    final icon = item.fundType == CooperativeFundType.principal
        ? AppIcons.savings
        : AppIcons.today;

    return Container(
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
                child: Icon(icon, color: AppColors.primaryDark, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
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
                      showTenant
                          ? '${item.memberName} - ${item.tenantName}'
                          : item.memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.custom(
                label: item.status.title,
                background: background,
                foreground: color,
                icon: item.isPaid ? AppIcons.check : AppIcons.pending,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AmountColumn(
                  label: 'Tagihan',
                  value: AppFormats.rupiahCompact(item.amountDue),
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Terbayar',
                  value: AppFormats.rupiahCompact(item.amountPaid),
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Sisa',
                  value: AppFormats.rupiahCompact(item.outstandingAmount),
                  danger: item.hasOutstanding,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jatuh tempo ${AppFormats.dateDay(item.dueDate)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canRecord)
                TextButton.icon(
                  onPressed: onRecord,
                  icon: const Icon(AppIcons.add, size: 16),
                  label: const Text('Catat'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: danger ? AppColors.dangerDark : AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentInput {
  const _PaymentInput({required this.amount, required this.note});

  final double amount;
  final String? note;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.item});

  final FundItem item;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.item.outstandingAmount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amount.text);
    Navigator.pop(
      context,
      _PaymentInput(
        amount: amount,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Catat Pembayaran',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.item.memberName} - ${widget.item.label}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RupiahField(
              label: 'Jumlah pembayaran',
              controller: _amount,
              helper:
                  'Sisa tagihan ${AppFormats.rupiah(widget.item.outstandingAmount)}',
            ),
            const SizedBox(height: 12),
            NoteField(controller: _note, label: 'Catatan'),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FormSubmitButton(
                label: 'Simpan Pembayaran',
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
