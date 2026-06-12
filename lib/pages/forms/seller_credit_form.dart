import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class SellerCreditForm extends StatefulWidget {
  const SellerCreditForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;

  @override
  State<SellerCreditForm> createState() => _SellerCreditFormState();
}

class _SellerCreditFormState extends State<SellerCreditForm> {
  final _formKey = GlobalKey<FormState>();
  final _sellerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _itemsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _sellerCtrl.text = r.primary;
      _amountCtrl.text = r.quantity.toString();
      _itemsCtrl.text = r.items;
      _noteCtrl.text = r.note;
    }
  }

  @override
  void dispose() {
    _sellerCtrl.dispose();
    _amountCtrl.dispose();
    _itemsCtrl.dispose();
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
        RecordPayloads.sellerCredit(
          sellerName: _sellerCtrl.text.trim(),
          amount: amount,
          items: _itemsCtrl.text.trim(),
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
            label: 'Nama Penjual',
            controller: _sellerCtrl,
            hint: 'Nama penjual / supplier',
          ),
          const SizedBox(height: 16),
          RupiahField(label: 'Jumlah Kredit', controller: _amountCtrl),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Barang / Item',
            controller: _itemsCtrl,
            required: false,
            maxLines: 2,
            hint: 'Daftar barang yang dikreditkan (opsional)',
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
