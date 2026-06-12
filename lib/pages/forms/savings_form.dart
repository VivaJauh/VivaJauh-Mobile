import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class SavingsForm extends StatefulWidget {
  const SavingsForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    this.initialDirection,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;
  final SavingsDirection? initialDirection;

  @override
  State<SavingsForm> createState() => _SavingsFormState();
}

class _SavingsFormState extends State<SavingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _memberCtrl = TextEditingController();
  final _memberIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late SavingsDirection _direction;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection ?? SavingsDirection.setor;
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _direction = r.savingsDirection;
      _memberCtrl.text = r.primary;
      _memberIdCtrl.text = r.memberId;
      _amountCtrl.text = r.quantity.toString();
      _noteCtrl.text = r.note;
    }
  }

  @override
  void dispose() {
    _memberCtrl.dispose();
    _memberIdCtrl.dispose();
    _amountCtrl.dispose();
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
        RecordPayloads.savings(
          memberName: _memberCtrl.text.trim(),
          direction: _direction,
          amount: amount,
          memberId: _memberIdCtrl.text.trim(),
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
          LabeledDropdown<SavingsDirection>(
            label: 'Jenis Transaksi',
            value: _direction,
            items: SavingsDirection.values,
            itemLabel: (d) => d.label,
            onChanged: (v) => setState(() => _direction = v!),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Nama Anggota',
            controller: _memberCtrl,
            hint: 'Nama lengkap anggota',
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'ID Anggota',
            controller: _memberIdCtrl,
            required: false,
            hint: 'Nomor anggota (opsional)',
          ),
          const SizedBox(height: 16),
          RupiahField(label: 'Jumlah', controller: _amountCtrl),
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
