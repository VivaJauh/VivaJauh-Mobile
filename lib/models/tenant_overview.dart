class MemberSummary {
  const MemberSummary({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.recordCount,
    required this.savingsTotal,
    required this.withdrawalsTotal,
    required this.repaymentTotal,
    required this.lastActivityAt,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final int recordCount;
  final double savingsTotal;
  final double withdrawalsTotal;
  final double repaymentTotal;
  final DateTime? lastActivityAt;

  double get savingsBalance => savingsTotal - withdrawalsTotal;

  factory MemberSummary.fromJson(Map<String, dynamic> json) => MemberSummary(
        userId: json['user_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        recordCount: (json['record_count'] as num? ?? 0).toInt(),
        savingsTotal: (json['savings_total'] as num? ?? 0).toDouble(),
        withdrawalsTotal:
            (json['withdrawals_total'] as num? ?? 0).toDouble(),
        repaymentTotal: (json['repayment_total'] as num? ?? 0).toDouble(),
        lastActivityAt: json['last_activity_at'] != null
            ? DateTime.tryParse(json['last_activity_at'] as String)?.toLocal()
            : null,
      );
}

class KoperasiSummary {
  const KoperasiSummary({
    required this.tenantId,
    required this.koperasiName,
    required this.focusArea,
    required this.memberCount,
    required this.recordCount,
    required this.savingsTotal,
    required this.repaymentTotal,
    required this.lastActivityAt,
  });

  final String tenantId;
  final String koperasiName;
  final String? focusArea;
  final int memberCount;
  final int recordCount;
  final double savingsTotal;
  final double repaymentTotal;
  final DateTime? lastActivityAt;

  factory KoperasiSummary.fromJson(Map<String, dynamic> json) =>
      KoperasiSummary(
        tenantId: json['tenant_id'] as String? ?? '',
        koperasiName: json['koperasi_name'] as String? ?? '',
        focusArea: json['focus_area'] as String?,
        memberCount: (json['member_count'] as num? ?? 0).toInt(),
        recordCount: (json['record_count'] as num? ?? 0).toInt(),
        savingsTotal: (json['savings_total'] as num? ?? 0).toDouble(),
        repaymentTotal: (json['repayment_total'] as num? ?? 0).toDouble(),
        lastActivityAt: json['last_activity_at'] != null
            ? DateTime.tryParse(json['last_activity_at'] as String)?.toLocal()
            : null,
      );
}
