library;

class PayloadKeys {
  const PayloadKeys._();

  static const primary = 'primary';
  static const quantity = 'quantity';
  static const secondary = 'secondary';
  static const note = 'note';
  static const recordedAt = 'recorded_at';
  static const officer = 'officer';
  static const schemaVersion = 'schema_version';

  static const direction = 'direction';
  static const adjustmentSign = 'adjustment_sign';
  static const warehouse = 'warehouse';

  static const eventType = 'event_type';
  static const pen = 'pen';
  static const healthNote = 'health_note';

  static const memberId = 'member_id';
  static const savingsDirection = 'savings_direction';
  static const loanRef = 'loan_ref';

  static const issues = 'issues';
  static const items = 'items';

  static const currentSchemaVersion = 2;
}

enum FeedDirection { masuk, keluar, rusak, penyesuaian }

extension FeedDirectionX on FeedDirection {
  String get apiValue => name;

  String get label => switch (this) {
        FeedDirection.masuk => 'Masuk',
        FeedDirection.keluar => 'Keluar',
        FeedDirection.rusak => 'Rusak',
        FeedDirection.penyesuaian => 'Penyesuaian',
      };

  static FeedDirection? tryParse(String? value) {
    for (final direction in FeedDirection.values) {
      if (direction.name == value) return direction;
    }
    return null;
  }
}

enum LivestockEventType {
  penambahan,
  pengurangan,
  kematian,
  catatanKesehatan,
  penggunaanPakan,
}

extension LivestockEventTypeX on LivestockEventType {
  String get apiValue => switch (this) {
        LivestockEventType.penambahan => 'penambahan',
        LivestockEventType.pengurangan => 'pengurangan',
        LivestockEventType.kematian => 'kematian',
        LivestockEventType.catatanKesehatan => 'catatan_kesehatan',
        LivestockEventType.penggunaanPakan => 'penggunaan_pakan',
      };

  String get label => switch (this) {
        LivestockEventType.penambahan => 'Penambahan',
        LivestockEventType.pengurangan => 'Pengurangan',
        LivestockEventType.kematian => 'Kematian',
        LivestockEventType.catatanKesehatan => 'Catatan Kesehatan',
        LivestockEventType.penggunaanPakan => 'Penggunaan Pakan',
      };

  bool get quantityIsKg => this == LivestockEventType.penggunaanPakan;

  static LivestockEventType? tryParse(String? value) {
    for (final type in LivestockEventType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

enum SavingsDirection { setor, tarik }

extension SavingsDirectionX on SavingsDirection {
  String get apiValue => name;

  String get label => switch (this) {
        SavingsDirection.setor => 'Setor',
        SavingsDirection.tarik => 'Tarik',
      };

  static SavingsDirection? tryParse(String? value) {
    for (final direction in SavingsDirection.values) {
      if (direction.name == value) return direction;
    }
    return null;
  }
}

class RecordPayloads {
  const RecordPayloads._();

  static Map<String, dynamic> _base({
    required String primary,
    required num quantity,
    required String secondary,
    required String note,
    required String officer,
    DateTime? recordedAt,
  }) {
    assert(primary.trim().isNotEmpty, 'primary wajib diisi');
    assert(quantity > 0, 'quantity harus > 0');
    return {
      PayloadKeys.primary: primary.trim(),
      PayloadKeys.quantity: quantity,
      PayloadKeys.secondary: secondary.trim(),
      PayloadKeys.note: note.trim(),
      PayloadKeys.recordedAt: (recordedAt ?? DateTime.now()).toIso8601String(),
      PayloadKeys.officer: officer,
      PayloadKeys.schemaVersion: PayloadKeys.currentSchemaVersion,
    };
  }

  static Map<String, dynamic> feed({
    required String feedType,
    required FeedDirection direction,
    required num quantityKg,
    int adjustmentSign = 1,
    String warehouse = '',
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: feedType,
      quantity: quantityKg,
      secondary: warehouse,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.direction: direction.apiValue,
    if (direction == FeedDirection.penyesuaian)
      PayloadKeys.adjustmentSign: adjustmentSign >= 0 ? 1 : -1,
    PayloadKeys.warehouse: warehouse.trim(),
  };

  static Map<String, dynamic> livestock({
    required String livestockType,
    required LivestockEventType eventType,
    required num quantity,
    String pen = '',
    String healthNote = '',
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: livestockType,
      quantity: quantity,
      secondary: pen,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.eventType: eventType.apiValue,
    PayloadKeys.pen: pen.trim(),
    PayloadKeys.healthNote: healthNote.trim(),
  };

  static Map<String, dynamic> savings({
    required String memberName,
    required SavingsDirection direction,
    required num amount,
    String memberId = '',
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: memberName,
      quantity: amount,
      secondary: memberId,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.savingsDirection: direction.apiValue,
    PayloadKeys.memberId: memberId.trim(),
  };

  static Map<String, dynamic> loanRepayment({
    required String memberName,
    required num amount,
    String memberId = '',
    String loanRef = '',
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: memberName,
      quantity: amount,
      secondary: loanRef,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.memberId: memberId.trim(),
    PayloadKeys.loanRef: loanRef.trim(),
  };

  static Map<String, dynamic> dailyReport({
    required String summary,
    String issues = '',
    num activityCount = 1,
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: summary,
      quantity: activityCount > 0 ? activityCount : 1,
      secondary: issues,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.issues: issues.trim(),
  };

  static Map<String, dynamic> sellerCredit({
    required String sellerName,
    required num amount,
    String items = '',
    String note = '',
    required String officer,
    DateTime? recordedAt,
  }) => {
    ..._base(
      primary: sellerName,
      quantity: amount,
      secondary: items,
      note: note,
      officer: officer,
      recordedAt: recordedAt,
    ),
    PayloadKeys.items: items.trim(),
  };
}

class PayloadReader {
  const PayloadReader(this.payload);

  final Map<String, dynamic> payload;

  String get primary =>
      (payload[PayloadKeys.primary] as String?)?.trim() ?? '';
  String get secondary =>
      (payload[PayloadKeys.secondary] as String?)?.trim() ?? '';
  String get note => (payload[PayloadKeys.note] as String?)?.trim() ?? '';
  String get officer =>
      (payload[PayloadKeys.officer] as String?)?.trim() ?? '';

  num get quantity {
    final raw = payload[PayloadKeys.quantity];
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw) ?? 0;
    return 0;
  }

  FeedDirection get feedDirection =>
      FeedDirectionX.tryParse(payload[PayloadKeys.direction] as String?) ??
      FeedDirection.masuk;

  int get adjustmentSign =>
      (payload[PayloadKeys.adjustmentSign] as num? ?? 1) < 0 ? -1 : 1;

  String get warehouse =>
      (payload[PayloadKeys.warehouse] as String?)?.trim() ?? secondary;

  LivestockEventType get livestockEventType =>
      LivestockEventTypeX.tryParse(
        payload[PayloadKeys.eventType] as String?,
      ) ??
      LivestockEventType.penambahan;

  String get pen =>
      (payload[PayloadKeys.pen] as String?)?.trim() ?? secondary;
  String get healthNote =>
      (payload[PayloadKeys.healthNote] as String?)?.trim() ?? '';

  SavingsDirection get savingsDirection =>
      SavingsDirectionX.tryParse(
        payload[PayloadKeys.savingsDirection] as String?,
      ) ??
      SavingsDirection.setor;

  String get memberId =>
      (payload[PayloadKeys.memberId] as String?)?.trim() ?? '';
  String get loanRef =>
      (payload[PayloadKeys.loanRef] as String?)?.trim() ?? secondary;
  String get issues =>
      (payload[PayloadKeys.issues] as String?)?.trim() ?? secondary;
  String get items =>
      (payload[PayloadKeys.items] as String?)?.trim() ?? secondary;
}
