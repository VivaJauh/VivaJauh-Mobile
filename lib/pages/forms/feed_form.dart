import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/formats.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class FeedForm extends StatefulWidget {
  const FeedForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    this.stockByType,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;
  final Map<String, double>? stockByType;

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

  double? get _availableStock => widget.stockByType?[_resolvedFeedType] ?? 0;

  bool get _isOutgoing =>
      _direction == FeedDirection.keluar || _direction == FeedDirection.rusak;

  /// Batas keras: keluar/rusak tidak boleh melebihi stok tercatat.
  double? get _qtyMax {
    if (widget.stockByType == null || !_isOutgoing) return null;
    return _availableStock ?? 0;
  }

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
            helper: widget.stockByType != null
                ? 'Stok $_resolvedFeedType tercatat: ${AppFormats.kg(_availableStock ?? 0)}'
                : null,
            maxValue: _qtyMax,
            maxValueMessage: _qtyMax != null
                ? 'Maksimal ${AppFormats.kg(_qtyMax!)} (stok saat ini)'
                : null,
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
