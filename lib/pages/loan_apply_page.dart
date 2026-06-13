import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/loan_service.dart';
import '../utils/error_messages.dart';
import '../widgets/widgets.dart';

const kKoperasiOptions = [
  'Padiwangi',
  'Melati Jaya',
  'Sumber Makmur',
  'Tirta Bersama',
  'Harapan Baru',
];

const kTenureOptions = [3, 6, 12, 18, 24];

class LoanApplyPage extends StatelessWidget {
  const LoanApplyPage({
    required this.session,
    required this.online,
    required this.onSaveOffline,
    super.key,
  });

  final AuthSession session;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onSaveOffline;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LoanApplyBloc(loanService: const LoanService(), session: session),
      child: _LoanApplyView(
        session: session,
        online: online,
        onSaveOffline: onSaveOffline,
      ),
    );
  }
}

class LoanApplyResult {
  const LoanApplyResult.created(this.created) : queued = false;
  const LoanApplyResult.queued() : created = null, queued = true;

  final LoanApplication? created;
  final bool queued;
}

class _LoanApplyView extends StatefulWidget {
  const _LoanApplyView({
    required this.session,
    required this.online,
    required this.onSaveOffline,
  });

  final AuthSession session;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onSaveOffline;

  @override
  State<_LoanApplyView> createState() => _LoanApplyViewState();
}

class _LoanApplyViewState extends State<_LoanApplyView> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _memberId = TextEditingController();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();

  String _koperasi = kKoperasiOptions.first;
  int _tenure = kTenureOptions[2];
  bool _savingOffline = false;

  bool get _isMember => widget.session.role == 'member';

  @override
  void initState() {
    super.initState();
    if (_isMember) {
      _name.text = widget.session.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _memberId.dispose();
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final amount = int.parse(_amount.text);
    return RecordPayloads.loanApplication(
      applicantName: _name.text.trim(),
      applicantMemberId: _memberId.text.trim(),
      targetKoperasi: _koperasi,
      requestedAmount: amount,
      tenureMonths: _tenure,
      purpose: _purpose.text.trim(),
      officer: widget.session.name,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.online) {
      setState(() => _savingOffline = true);
      try {
        await widget.onSaveOffline(RecordType.loanApplication, _payload());
        if (!mounted) return;
        Navigator.pop(context, const LoanApplyResult.queued());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      } finally {
        if (mounted) setState(() => _savingOffline = false);
      }
      return;
    }

    context.read<LoanApplyBloc>().add(
      LoanApplySubmitted(
        applicantName: _name.text.trim(),
        applicantMemberId: _memberId.text.trim().isEmpty
            ? null
            : _memberId.text.trim(),
        targetKoperasi: _koperasi,
        requestedAmount: int.parse(_amount.text),
        tenureMonths: _tenure,
        purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<LoanApplyBloc>().state.submitting;
    final saving = submitting || _savingOffline;

    return BlocListener<LoanApplyBloc, LoanApplyState>(
      listenWhen: (previous, current) =>
          (current.created != null && previous.created != current.created) ||
          previous.errorId != current.errorId,
      listener: (context, state) {
        if (state.created != null) {
          Navigator.pop(context, LoanApplyResult.created(state.created!));
          return;
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajukan Pinjaman')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.online) ...[
                  const OfflineHintCard(),
                  const SizedBox(height: 16),
                ],
                const _CrossCheckInfoCard(),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Nama anggota pemohon',
                  controller: _name,
                  hint: 'Contoh: Pak Hendra',
                  readOnly: _isMember,
                  helper: _isMember
                      ? 'Nama otomatis dari akun yang sedang login'
                      : null,
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'NIK / ID anggota',
                  controller: _memberId,
                  required: false,
                  hint: 'Opsional',
                  helper:
                      'NIK dipakai untuk mencocokkan riwayat anggota lintas koperasi',
                ),
                const SizedBox(height: 14),
                LabeledDropdown<String>(
                  label: 'Koperasi tujuan',
                  value: _koperasi,
                  items: kKoperasiOptions,
                  itemLabel: (value) => value,
                  onChanged: (value) =>
                      setState(() => _koperasi = value ?? _koperasi),
                ),
                const SizedBox(height: 14),
                RupiahField(label: 'Jumlah pinjaman', controller: _amount),
                const SizedBox(height: 14),
                LabeledDropdown<int>(
                  label: 'Tenor',
                  value: _tenure,
                  items: kTenureOptions,
                  itemLabel: (value) => '$value bulan',
                  onChanged: (value) =>
                      setState(() => _tenure = value ?? _tenure),
                ),
                const SizedBox(height: 14),
                NoteField(controller: _purpose, label: 'Tujuan pinjaman'),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FormSubmitButton(
                    label: widget.online
                        ? 'Ajukan & Analisis Riwayat'
                        : 'Simpan untuk Sinkronisasi',
                    saving: saving,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossCheckInfoCard extends StatelessWidget {
  const _CrossCheckInfoCard();

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
          const Icon(AppIcons.ai, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sistem akan memeriksa riwayat pinjaman anggota lintas koperasi '
              'selama 12 bulan terakhir dan memberikan rekomendasi risiko. '
              'Keputusan akhir tetap di secondary admin koperasi sekunder.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
