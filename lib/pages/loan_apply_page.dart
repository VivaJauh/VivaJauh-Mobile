import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/loan_service.dart';
import '../widgets/widgets.dart';

const kKoperasiOptions = [
  'Padiwangi',
  'Melati Jaya',
  'Sumber Makmur',
  'Tirta Bersama',
  'Harapan Baru',
];

const kTenureOptions = [3, 6, 12, 18, 24];

class LoanApplyPage extends StatefulWidget {
  const LoanApplyPage({required this.session, super.key});

  final AuthSession session;

  @override
  State<LoanApplyPage> createState() => _LoanApplyPageState();
}

class _LoanApplyPageState extends State<LoanApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _loanService = const LoanService();

  final _name = TextEditingController();
  final _memberId = TextEditingController();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();

  String _koperasi = kKoperasiOptions.first;
  int _tenure = kTenureOptions[2];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _memberId.dispose();
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await _loanService.create(
        widget.session,
        applicantName: _name.text.trim(),
        applicantMemberId:
            _memberId.text.trim().isEmpty ? null : _memberId.text.trim(),
        targetKoperasi: _koperasi,
        requestedAmount: int.parse(_amount.text),
        tenureMonths: _tenure,
        purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Pinjaman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CrossCheckInfoCard(),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Nama anggota pemohon',
                controller: _name,
                hint: 'Contoh: Pak Hendra',
              ),
              const SizedBox(height: 14),
              LabeledTextField(
                label: 'ID anggota',
                controller: _memberId,
                required: false,
                hint: 'Opsional',
                helper: 'Isi jika anggota punya nomor keanggotaan',
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
              RupiahField(
                label: 'Jumlah pinjaman',
                controller: _amount,
              ),
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
                  label: 'Ajukan & Analisis Riwayat',
                  saving: _saving,
                  onPressed: _submit,
                ),
              ),
            ],
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
              'dan memberikan rekomendasi risiko. Keputusan akhir tetap di admin koperasi.',
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
