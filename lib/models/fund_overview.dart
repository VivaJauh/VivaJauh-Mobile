enum CooperativeFundType {
  principal,
  monthlyDues;

  String get apiValue => switch (this) {
        CooperativeFundType.principal => 'principal',
        CooperativeFundType.monthlyDues => 'monthly_dues',
      };

  String get title => switch (this) {
        CooperativeFundType.principal => 'Dana Pokok',
        CooperativeFundType.monthlyDues => 'Dana Iuran',
      };

  static CooperativeFundType fromApi(String value) => switch (value) {
        'monthly_dues' => CooperativeFundType.monthlyDues,
        _ => CooperativeFundType.principal,
      };
}

enum FundPaymentStatus {
  unpaid,
  partial,
  paid,
  overdue;

  String get title => switch (this) {
        FundPaymentStatus.unpaid => 'Belum Bayar',
        FundPaymentStatus.partial => 'Sebagian',
        FundPaymentStatus.paid => 'Lunas',
        FundPaymentStatus.overdue => 'Lewat Tempo',
      };

  static FundPaymentStatus fromApi(String value) => switch (value) {
        'partial' => FundPaymentStatus.partial,
        'paid' => FundPaymentStatus.paid,
        'overdue' => FundPaymentStatus.overdue,
        _ => FundPaymentStatus.unpaid,
      };
}

class FundOverview {
  const FundOverview({
    required this.generatedAt,
    required this.scope,
    required this.currentPeriod,
    required this.iuranDueDate,
    required this.principalAmount,
    required this.monthlyDuesAmount,
    required this.totals,
    required this.items,
  });

  final DateTime generatedAt;
  final String scope;
  final String currentPeriod;
  final DateTime iuranDueDate;
  final double principalAmount;
  final double monthlyDuesAmount;
  final FundTotals totals;
  final List<FundItem> items;

  factory FundOverview.fromJson(Map<String, dynamic> json) => FundOverview(
        generatedAt:
            DateTime.tryParse(json['generated_at'] as String? ?? '') ??
                DateTime.now(),
        scope: json['scope'] as String? ?? 'member',
        currentPeriod: json['current_period'] as String? ?? '',
        iuranDueDate:
            DateTime.tryParse(json['iuran_due_date'] as String? ?? '') ??
                DateTime.now(),
        principalAmount: (json['principal_amount'] as num? ?? 0).toDouble(),
        monthlyDuesAmount:
            (json['monthly_dues_amount'] as num? ?? 0).toDouble(),
        totals: FundTotals.fromJson(
          Map<String, dynamic>.from(json['totals'] as Map? ?? {}),
        ),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => FundItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class FundTotals {
  const FundTotals({
    required this.memberCount,
    required this.obligationCount,
    required this.principalDueTotal,
    required this.monthlyDueTotal,
    required this.paidTotal,
    required this.outstandingTotal,
    required this.overdueTotal,
  });

  final int memberCount;
  final int obligationCount;
  final double principalDueTotal;
  final double monthlyDueTotal;
  final double paidTotal;
  final double outstandingTotal;
  final double overdueTotal;

  factory FundTotals.fromJson(Map<String, dynamic> json) => FundTotals(
        memberCount: (json['member_count'] as num? ?? 0).toInt(),
        obligationCount: (json['obligation_count'] as num? ?? 0).toInt(),
        principalDueTotal:
            (json['principal_due_total'] as num? ?? 0).toDouble(),
        monthlyDueTotal: (json['monthly_due_total'] as num? ?? 0).toDouble(),
        paidTotal: (json['paid_total'] as num? ?? 0).toDouble(),
        outstandingTotal:
            (json['outstanding_total'] as num? ?? 0).toDouble(),
        overdueTotal: (json['overdue_total'] as num? ?? 0).toDouble(),
      );
}

class FundItem {
  const FundItem({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantType,
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.fundType,
    required this.label,
    required this.periodKey,
    required this.amountDue,
    required this.amountPaid,
    required this.outstandingAmount,
    required this.status,
    required this.dueDate,
    required this.paidAt,
    required this.recordedBy,
    required this.recorderName,
    required this.note,
  });

  final String id;
  final String tenantId;
  final String tenantName;
  final String tenantType;
  final String memberId;
  final String memberName;
  final String memberEmail;
  final CooperativeFundType fundType;
  final String label;
  final String periodKey;
  final double amountDue;
  final double amountPaid;
  final double outstandingAmount;
  final FundPaymentStatus status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? recordedBy;
  final String? recorderName;
  final String? note;

  bool get isPaid => status == FundPaymentStatus.paid;
  bool get hasOutstanding => outstandingAmount > 0;

  factory FundItem.fromJson(Map<String, dynamic> json) => FundItem(
        id: json['id'] as String? ?? '',
        tenantId: json['tenant_id'] as String? ?? '',
        tenantName: json['tenant_name'] as String? ?? '',
        tenantType: json['tenant_type'] as String? ?? '',
        memberId: json['member_id'] as String? ?? '',
        memberName: json['member_name'] as String? ?? '',
        memberEmail: json['member_email'] as String? ?? '',
        fundType: CooperativeFundType.fromApi(
          json['fund_type'] as String? ?? 'principal',
        ),
        label: json['label'] as String? ?? '',
        periodKey: json['period_key'] as String? ?? '',
        amountDue: (json['amount_due'] as num? ?? 0).toDouble(),
        amountPaid: (json['amount_paid'] as num? ?? 0).toDouble(),
        outstandingAmount:
            (json['outstanding_amount'] as num? ?? 0).toDouble(),
        status: FundPaymentStatus.fromApi(json['status'] as String? ?? ''),
        dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ??
            DateTime.now(),
        paidAt: json['paid_at'] != null
            ? DateTime.tryParse(json['paid_at'] as String)
            : null,
        recordedBy: json['recorded_by'] as String?,
        recorderName: json['recorder_name'] as String?,
        note: json['note'] as String?,
      );
}
