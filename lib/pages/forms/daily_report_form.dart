import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'form_shared.dart';

class DailyReportForm extends StatefulWidget {
  const DailyReportForm({
    required this.officer,
    required this.onSubmit,
    this.initialPayload,
    super.key,
  });

  final String officer;
  final PayloadSubmit onSubmit;
  final Map<String, dynamic>? initialPayload;

  @override
  State<DailyReportForm> createState() => _DailyReportFormState();
}

class _DailyReportFormState extends State<DailyReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _summaryCtrl = TextEditingController();
  final _issuesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.initialPayload;
    if (payload != null) {
      final r = PayloadReader(payload);
      _summaryCtrl.text = r.primary;
      _issuesCtrl.text = r.issues;
      _noteCtrl.text = r.note;
    }
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _issuesCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        RecordPayloads.dailyReport(
          summary: _summaryCtrl.text.trim(),
          issues: _issuesCtrl.text.trim(),
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
            label: 'Ringkasan Hari Ini',
            controller: _summaryCtrl,
            maxLines: 3,
            hint: 'Ceritakan apa yang terjadi hari ini...',
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Masalah / Kendala',
            controller: _issuesCtrl,
            required: false,
            maxLines: 2,
            hint: 'Jika ada kendala, tuliskan di sini (opsional)',
          ),
          const SizedBox(height: 16),
          NoteField(controller: _noteCtrl),
          const SizedBox(height: 24),
          FormSubmitButton(
            label: 'Simpan Laporan',
            onPressed: _submit,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
