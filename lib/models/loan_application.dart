enum LoanStatus { draft, pendingReview, approved, rejected }

enum LoanRiskLevel { low, medium, high }

extension LoanStatusX on LoanStatus {
  String get apiValue => switch (this) {
        LoanStatus.draft => 'draft',
        LoanStatus.pendingReview => 'pending_review',
        LoanStatus.approved => 'approved',
        LoanStatus.rejected => 'rejected',
      };

  String get title => switch (this) {
        LoanStatus.draft => 'Draf',
        LoanStatus.pendingReview => 'Menunggu Review',
        LoanStatus.approved => 'Disetujui',
        LoanStatus.rejected => 'Ditolak',
      };

  static LoanStatus fromApiValue(String? value) => switch (value) {
        'draft' => LoanStatus.draft,
        'approved' => LoanStatus.approved,
        'rejected' => LoanStatus.rejected,
        _ => LoanStatus.pendingReview,
      };
}

extension LoanRiskLevelX on LoanRiskLevel {
  String get title => switch (this) {
        LoanRiskLevel.low => 'Risiko Rendah',
        LoanRiskLevel.medium => 'Risiko Sedang',
        LoanRiskLevel.high => 'Risiko Tinggi',
      };

  static LoanRiskLevel fromApiValue(String? value) => switch (value) {
        'low' => LoanRiskLevel.low,
        'high' => LoanRiskLevel.high,
        _ => LoanRiskLevel.medium,
      };
}

class LoanEvidence {
  const LoanEvidence({
    required this.koperasi,
    required this.finding,
    required this.status,
  });

  final String koperasi;
  final String finding;
  final String status;

  factory LoanEvidence.fromJson(Map<String, dynamic> json) => LoanEvidence(
        koperasi: json['koperasi'] as String? ?? '',
        finding: json['finding'] as String? ?? '',
        status: json['status'] as String? ?? 'unknown',
      );
}

class LoanRecommendation {
  const LoanRecommendation({
    required this.riskLevel,
    required this.recommendation,
    required this.summary,
    required this.keyStats,
    required this.evidence,
    required this.modelProvider,
  });

  final LoanRiskLevel riskLevel;
  final String recommendation;
  final String summary;
  final Map<String, dynamic> keyStats;
  final List<LoanEvidence> evidence;
  final String modelProvider;

  String get recommendationTitle => switch (recommendation) {
        'approve' => 'Layak Disetujui',
        'manual_review' => 'Perlu Review Manual',
        _ => 'Perlu Pelunasan Dahulu',
      };

  bool get fromAi => modelProvider.startsWith('gemini');

  factory LoanRecommendation.fromJson(Map<String, dynamic> json) =>
      LoanRecommendation(
        riskLevel: LoanRiskLevelX.fromApiValue(json['risk_level'] as String?),
        recommendation: json['recommendation'] as String? ?? 'manual_review',
        summary: json['summary'] as String? ?? '',
        keyStats: Map<String, dynamic>.from(json['key_stats'] as Map? ?? {}),
        evidence: (json['evidence'] as List<dynamic>? ?? [])
            .map(
              (item) =>
                  LoanEvidence.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        modelProvider: json['model_provider'] as String? ?? 'rule_based',
      );
}

class LoanApplication {
  const LoanApplication({
    required this.id,
    required this.applicantName,
    required this.applicantMemberId,
    required this.targetKoperasi,
    required this.requestedAmount,
    required this.purpose,
    required this.tenureMonths,
    required this.status,
    required this.reviewNote,
    required this.reviewedAt,
    required this.createdAt,
    required this.recommendation,
  });

  final String id;
  final String applicantName;
  final String? applicantMemberId;
  final String targetKoperasi;
  final double requestedAmount;
  final String? purpose;
  final int tenureMonths;
  final LoanStatus status;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final LoanRecommendation? recommendation;

  factory LoanApplication.fromJson(Map<String, dynamic> json) =>
      LoanApplication(
        id: json['id'] as String? ?? '',
        applicantName: json['applicant_name'] as String? ?? '',
        applicantMemberId: json['applicant_member_id'] as String?,
        targetKoperasi: json['target_koperasi'] as String? ?? '',
        requestedAmount: (json['requested_amount'] as num? ?? 0).toDouble(),
        purpose: json['purpose'] as String?,
        tenureMonths: (json['tenure_months'] as num? ?? 0).toInt(),
        status: LoanStatusX.fromApiValue(json['status'] as String?),
        reviewNote: json['review_note'] as String?,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.tryParse(json['reviewed_at'] as String)
            : null,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
        recommendation: json['recommendation'] != null
            ? LoanRecommendation.fromJson(
                Map<String, dynamic>.from(json['recommendation'] as Map),
              )
            : null,
      );
}
