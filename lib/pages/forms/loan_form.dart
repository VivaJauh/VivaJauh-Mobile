import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class LoanForm extends StatefulWidget {
  const LoanForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;

  @override
  State<LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  final _formKey = GlobalKey<FormState>();
  final _memberCtrl = TextEditingController();
  final _memberIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _loanRefCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _memberCtrl.text = r.primary;
      _memberIdCtrl.text = r.memberId;
      _amountCtrl.text = r.quantity.toString();
      _loanRefCtrl.text = r.loanRef;
      _noteCtrl.text = r.note;
    }
  }

  @override
  void dispose() {
    _memberCtrl.dispose();
    _memberIdCtrl.dispose();
    _amountCtrl.dispose();
    _loanRefCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        RecordPayloads.loanRepayment(
          memberName: _memberCtrl.text.trim(),
          amount: amount,
          memberId: _memberIdCtrl.text.trim(),
          loanRef: _loanRefCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
          officer: widget.officer,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineHintCard(),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'Nama Anggota',
            controller: _memberCtrl,
            hint: 'Nama anggota peminjam',
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'ID Anggota',
            controller: _memberIdCtrl,
            required: false,
            hint: 'Nomor anggota (opsional)',
          ),
          const SizedBox(height: 16),
          RupiahField(label: 'Jumlah Cicilan', controller: _amountCtrl),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Referensi Pinjaman',
            controller: _loanRefCtrl,
            required: false,
            hint: 'Nomor / referensi pinjaman (opsional)',
          ),
          const SizedBox(height: 16),
          NoteField(controller: _noteCtrl),
          const SizedBox(height: 24),
          FormSubmitButton(
            label: 'Simpan Catatan',
            onPressed: _submit,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
