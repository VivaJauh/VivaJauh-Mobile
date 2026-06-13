enum RecordType {
  feedTransaction,
  livestockEvent,
  sellerCredit,
  savingsTransaction,
  loanRepayment,
  loanApplication,
  dailyReport,
  correction,
}

enum SyncStatus { pending, syncing, synced, failed, conflict }

enum VerificationStatus { unverified, verified, rejected, needsCorrection }

extension RecordTypeX on RecordType {
  String get apiValue => switch (this) {
    RecordType.feedTransaction => 'feed_transaction',
    RecordType.livestockEvent => 'livestock_event',
    RecordType.sellerCredit => 'seller_credit',
    RecordType.savingsTransaction => 'savings_transaction',
    RecordType.loanRepayment => 'loan_repayment',
    RecordType.loanApplication => 'loan_application',
    RecordType.dailyReport => 'daily_report',
    RecordType.correction => 'correction',
  };

  String get title => switch (this) {
    RecordType.feedTransaction => 'Transaksi Pakan',
    RecordType.livestockEvent => 'Event Ternak',
    RecordType.sellerCredit => 'Seller Credit',
    RecordType.savingsTransaction => 'Simpanan Anggota',
    RecordType.loanRepayment => 'Cicilan Pinjaman',
    RecordType.loanApplication => 'Pengajuan Pinjaman',
    RecordType.dailyReport => 'Laporan Harian',
    RecordType.correction => 'Koreksi Data',
  };

  static RecordType fromApiValue(String value) => RecordType.values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => RecordType.dailyReport,
  );
}

extension SyncStatusX on SyncStatus {
  String get apiValue => switch (this) {
    SyncStatus.pending => 'pending',
    SyncStatus.syncing => 'syncing',
    SyncStatus.synced => 'synced',
    SyncStatus.failed => 'failed',
    SyncStatus.conflict => 'conflict',
  };

  static SyncStatus fromApiValue(String value) => SyncStatus.values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => SyncStatus.pending,
  );
}

extension VerificationStatusX on VerificationStatus {
  String get apiValue => switch (this) {
    VerificationStatus.unverified => 'unverified',
    VerificationStatus.verified => 'verified',
    VerificationStatus.rejected => 'rejected',
    VerificationStatus.needsCorrection => 'needs_correction',
  };

  static VerificationStatus fromApiValue(String value) =>
      VerificationStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => VerificationStatus.unverified,
      );
}
