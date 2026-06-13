import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../widgets/widgets.dart';
import 'forms/daily_report_form.dart';
import 'forms/feed_form.dart';
import 'forms/form_shared.dart';
import 'forms/livestock_form.dart';
import 'forms/loan_form.dart';
import 'forms/savings_form.dart';
import 'forms/seller_credit_form.dart';

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({
    required this.session,
    required this.onSave,
    this.recordType,
    this.initialRecord,
    this.records,
    super.key,
  }) : assert(
         recordType != null || initialRecord != null,
         'recordType or initialRecord must be provided',
       );

  final AuthSession session;
  final Future<void> Function(RecordType, Map<String, dynamic>) onSave;
  final RecordType? recordType;
  final OfflineRecord? initialRecord;
  final List<OfflineRecord>? records;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  late RecordType _recordType;

  @override
  void initState() {
    super.initState();
    _recordType = widget.recordType ?? widget.initialRecord!.recordType;
  }

  String get _title {
    if (widget.initialRecord != null) return 'Ajukan Koreksi';
    return 'Tambah ${_recordType.title}';
  }

  Future<void> _onSubmit(Map<String, dynamic> payload) async {
    await widget.onSave(_recordType, payload);
    if (mounted) Navigator.pop(context);
  }

  Map<String, dynamic>? get _initialPayload =>
      widget.initialRecord?.payloadJson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.initialRecord != null) ...[
              _CorrectionBanner(original: widget.initialRecord!),
              const SizedBox(height: 16),
            ],
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final officer = widget.session.name;
    final initial = _initialPayload;
    return switch (_recordType) {
      RecordType.feedTransaction => FeedForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
        stockByType: widget.records != null
            ? Aggregator.computeFeedStock(widget.records!).balanceByType
            : null,
      ),
      RecordType.livestockEvent => LivestockForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
        populationByType: widget.records != null
            ? Aggregator.computeLivestock(widget.records!).populationByType
            : null,
      ),
      RecordType.savingsTransaction => SavingsForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
        balanceByMember: widget.records != null
            ? Aggregator.computeSavingsLoan(widget.records!).savingsByMember
            : null,
      ),
      RecordType.loanRepayment => LoanForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
      ),
      RecordType.loanApplication => _CorrectionTextForm(
        officer: officer,
        onSubmit: _onSubmit,
      ),
      RecordType.dailyReport => DailyReportForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
      ),
      RecordType.sellerCredit => SellerCreditForm(
        officer: officer,
        onSubmit: _onSubmit,
        initialPayload: initial,
      ),
      RecordType.correction => _CorrectionTextForm(
        officer: officer,
        onSubmit: _onSubmit,
      ),
    };
  }
}

class _CorrectionBanner extends StatelessWidget {
  const _CorrectionBanner({required this.original});

  final OfflineRecord original;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.appendOnly,
            color: AppColors.warningDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Koreksi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warningDark,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Data asli tidak diubah. Koreksi akan dibuat sebagai catatan baru.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionTextForm extends StatefulWidget {
  const _CorrectionTextForm({required this.officer, required this.onSubmit});

  final String officer;
  final PayloadSubmit onSubmit;

  @override
  State<_CorrectionTextForm> createState() => _CorrectionTextFormState();
}

class _CorrectionTextFormState extends State<_CorrectionTextForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        PayloadKeys.primary: _reasonCtrl.text.trim(),
        PayloadKeys.quantity: 1,
        PayloadKeys.secondary: '',
        PayloadKeys.note: '',
        PayloadKeys.officer: widget.officer,
        PayloadKeys.schemaVersion: PayloadKeys.currentSchemaVersion,
      });
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
            label: 'Alasan Koreksi',
            controller: _reasonCtrl,
            maxLines: 4,
            hint: 'Jelaskan alasan dan data yang benar...',
          ),
          const SizedBox(height: 24),
          FormSubmitButton(
            label: 'Kirim Koreksi',
            onPressed: _submit,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}
