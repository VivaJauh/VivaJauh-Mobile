import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/formats.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class LivestockForm extends StatefulWidget {
  const LivestockForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    this.populationByType,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;
  final Map<String, double>? populationByType;

  @override
  State<LivestockForm> createState() => _LivestockFormState();
}

class _LivestockFormState extends State<LivestockForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _penCtrl = TextEditingController();
  final _healthNoteCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customTypeCtrl = TextEditingController();

  LivestockEventType _eventType = LivestockEventType.penambahan;
  String _typeSelection = kLivestockTypeOptions.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _eventType = r.livestockEventType;
      _qtyCtrl.text = r.quantity.toString();
      _penCtrl.text = r.pen;
      _healthNoteCtrl.text = r.healthNote;
      _noteCtrl.text = r.note;
      final resolved = resolveDropdownInitial(r.primary, kLivestockTypeOptions);
      _typeSelection = resolved.selection;
      _customTypeCtrl.text = resolved.custom;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _penCtrl.dispose();
    _healthNoteCtrl.dispose();
    _noteCtrl.dispose();
    _customTypeCtrl.dispose();
    super.dispose();
  }

  String get _resolvedType =>
      _typeSelection == 'Lainnya' && _customTypeCtrl.text.trim().isNotEmpty
          ? _customTypeCtrl.text.trim()
          : _typeSelection;

  String get _qtyLabel => _eventType.quantityIsKg ? 'Jumlah (kg)' : 'Jumlah (ekor)';

  bool get _reducesPopulation =>
      _eventType == LivestockEventType.pengurangan ||
      _eventType == LivestockEventType.kematian;

  bool get _addsPopulation => _eventType == LivestockEventType.penambahan;

  double? get _currentPopulation => widget.populationByType?[_resolvedType] ?? 0;

  String? get _qtyHelper {
    if (_eventType.quantityIsKg) return null;
    if (_addsPopulation) return 'Menambah populasi $_resolvedType';
    if (_reducesPopulation) {
      final current = _currentPopulation ?? 0;
      return 'Mengurangi populasi · saat ini ${AppFormats.ekor(current)}';
    }
    return null;
  }

  Future<bool> _confirmOverdraw(double current, double qty) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Populasi Tidak Mencukupi'),
        content: Text(
          'Populasi $_resolvedType tercatat hanya ${AppFormats.ekor(current)}, '
          'sedangkan kamu mencatat ${_eventType.label.toLowerCase()} ${AppFormats.ekor(qty)}.\n\n'
          'Catatan tetap bisa disimpan, tapi populasi jenis ini akan minus '
          'dan perlu dikoreksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tetap Simpan'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = parseFlexibleNumber(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;

    if (widget.populationByType != null && _reducesPopulation) {
      final current = _currentPopulation ?? 0;
      if (qty > current && !await _confirmOverdraw(current, qty)) return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        RecordPayloads.livestock(
          livestockType: _resolvedType,
          eventType: _eventType,
          quantity: qty,
          pen: _penCtrl.text.trim(),
          healthNote: _healthNoteCtrl.text.trim(),
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
          LabeledDropdown<LivestockEventType>(
            label: 'Jenis Kejadian',
            value: _eventType,
            items: LivestockEventType.values,
            itemLabel: (e) => e.label,
            onChanged: (v) => setState(() => _eventType = v!),
          ),
          const SizedBox(height: 16),
          LabeledDropdown<String>(
            label: 'Jenis Ternak',
            value: _typeSelection,
            items: kLivestockTypeOptions,
            itemLabel: (s) => s,
            onChanged: (v) => setState(() => _typeSelection = v!),
          ),
          if (_typeSelection == 'Lainnya') ...[
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Nama Ternak',
              controller: _customTypeCtrl,
              hint: 'Contoh: Bebek',
            ),
          ],
          const SizedBox(height: 16),
          QtyField(
            label: _qtyLabel,
            controller: _qtyCtrl,
            suffix: _eventType.quantityIsKg ? 'kg' : 'ekor',
            helper: _qtyHelper,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Kandang',
            controller: _penCtrl,
            required: false,
            hint: 'Nama/nomor kandang (opsional)',
          ),
          if (_eventType == LivestockEventType.catatanKesehatan) ...[
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Catatan Kesehatan',
              controller: _healthNoteCtrl,
              maxLines: 2,
              hint: 'Gejala, treatment, dll.',
            ),
          ],
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
