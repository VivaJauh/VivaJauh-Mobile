import 'package:flutter/material.dart';

import '../../models/models.dart';

typedef PayloadSubmit = Future<void> Function(Map<String, dynamic> payload);

const kFeedTypeOptions = [
  'Konsentrat',
  'Dedak',
  'Jagung Giling',
  'Rumput / Hijauan',
  'Silase',
  'Lainnya',
];

const kLivestockTypeOptions = [
  'Sapi',
  'Kambing',
  'Domba',
  'Ayam',
  'Lainnya',
];

({String selection, String custom}) resolveDropdownInitial(
  String? value,
  List<String> options,
) {
  if (value == null || value.isEmpty) {
    return (selection: options.first, custom: '');
  }
  if (options.contains(value)) return (selection: value, custom: '');
  return (selection: 'Lainnya', custom: value);
}

RecordType recordTypeFromPayload(Map<String, dynamic> payload) {
  if (payload.containsKey(PayloadKeys.direction)) {
    return RecordType.feedTransaction;
  }
  if (payload.containsKey(PayloadKeys.eventType)) {
    return RecordType.livestockEvent;
  }
  if (payload.containsKey(PayloadKeys.savingsDirection)) {
    return RecordType.savingsTransaction;
  }
  if (payload.containsKey(PayloadKeys.loanRef)) return RecordType.loanRepayment;
  if (payload.containsKey(PayloadKeys.items)) return RecordType.sellerCredit;
  return RecordType.dailyReport;
}

class FormPage extends StatelessWidget {
  const FormPage({
    required this.title,
    required this.form,
    super.key,
  });

  final String title;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: form,
      ),
    );
  }
}
