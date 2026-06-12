import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class FeedForm extends StatefulWidget {
  const FeedForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;

  @override
  State<FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<FeedForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _warehouseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customTypeCtrl = TextEditingController();

  FeedDirection _direction = FeedDirection.masuk;
  String _feedTypeSelection = kFeedTypeOptions.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _direction = r.feedDirection;
      _qtyCtrl.text = r.quantity.toString();
      _warehouseCtrl.text = r.warehouse;
      _noteCtrl.text = r.note;
      final resolved = resolveDropdownInitial(r.primary, kFeedTypeOptions);
      _feedTypeSelection = resolved.selection;
      _customTypeCtrl.text = resolved.custom;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _warehouseCtrl.dispose();
    _noteCtrl.dispose();
    _customTypeCtrl.dispose();
    super.dispose();
  }

  String get _resolvedFeedType =>
      _feedTypeSelection == 'Lainnya' && _customTypeCtrl.text.trim().isNotEmpty
          ? _customTypeCtrl.text.trim()
          : _feedTypeSelection;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = parseFlexibleNumber(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        RecordPayloads.feed(
          feedType: _resolvedFeedType,
          direction: _direction,
          quantityKg: qty,
          warehouse: _warehouseCtrl.text.trim(),
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
          LabeledDropdown<FeedDirection>(
            label: 'Arah Transaksi',
            value: _direction,
            items: FeedDirection.values,
            itemLabel: (d) => d.label,
            onChanged: (v) => setState(() => _direction = v!),
          ),
          const SizedBox(height: 16),
          LabeledDropdown<String>(
            label: 'Jenis Pakan',
            value: _feedTypeSelection,
            items: kFeedTypeOptions,
            itemLabel: (s) => s,
            onChanged: (v) => setState(() => _feedTypeSelection = v!),
          ),
          if (_feedTypeSelection == 'Lainnya') ...[
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Nama Pakan',
              controller: _customTypeCtrl,
              hint: 'Contoh: Ampas Tahu',
            ),
          ],
          const SizedBox(height: 16),
          QtyField(
            label: 'Jumlah',
            controller: _qtyCtrl,
            suffix: 'kg',
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Gudang',
            controller: _warehouseCtrl,
            required: false,
            hint: 'Nama gudang (opsional)',
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
