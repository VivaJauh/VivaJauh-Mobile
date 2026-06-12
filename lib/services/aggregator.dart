library;

import '../models/models.dart';

class FeedStockSummary {
  const FeedStockSummary({
    required this.totalBalanceKg,
    required this.balanceByType,
    required this.totalInKg,
    required this.totalOutKg,
    required this.totalDamagedKg,
    required this.history,
  });

  final double totalBalanceKg;
  final Map<String, double> balanceByType;
  final double totalInKg;
  final double totalOutKg;
  final double totalDamagedKg;
  final List<OfflineRecord> history;
}

class LivestockSummary {
  const LivestockSummary({
    required this.totalPopulation,
    required this.populationByType,
    required this.totalDeaths,
    required this.healthNotes,
    required this.feedUsageKg,
    required this.history,
  });

  final double totalPopulation;
  final Map<String, double> populationByType;
  final double totalDeaths;
  final int healthNotes;
  final double feedUsageKg;
  final List<OfflineRecord> history;
}

class SavingsLoanSummary {
  const SavingsLoanSummary({
    required this.savingsBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalRepayments,
    required this.savingsByMember,
    required this.repaymentsByMember,
    required this.savingsHistory,
    required this.loanHistory,
  });

  final double savingsBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalRepayments;
  final Map<String, double> savingsByMember;
  final Map<String, double> repaymentsByMember;
  final List<OfflineRecord> savingsHistory;
  final List<OfflineRecord> loanHistory;
}

class SyncDelayEntry {
  const SyncDelayEntry({required this.record, required this.delay});

  final OfflineRecord record;
  final Duration delay;
}

class SyncDelaySummary {
  const SyncDelaySummary({
    required this.entries,
    required this.averageDelay,
    required this.maxDelay,
  });

  final List<SyncDelayEntry> entries;
  final Duration averageDelay;
  final Duration maxDelay;
}

class Aggregator {
  const Aggregator._();

  static List<OfflineRecord> _ofType(
    List<OfflineRecord> records,
    RecordType type,
  ) =>
      records.where((r) => r.recordType == type).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  static double feedDelta(OfflineRecord record) {
    final reader = PayloadReader(record.payloadJson);
    final qty = reader.quantity.toDouble();
    return switch (reader.feedDirection) {
      FeedDirection.masuk => qty,
      FeedDirection.keluar => -qty,
      FeedDirection.rusak => -qty,
      FeedDirection.penyesuaian => reader.adjustmentSign * qty,
    };
  }

  static FeedStockSummary computeFeedStock(List<OfflineRecord> records) {
    final history = _ofType(records, RecordType.feedTransaction);
    final balanceByType = <String, double>{};
    var totalIn = 0.0, totalOut = 0.0, totalDamaged = 0.0;

    for (final record in history) {
      final reader = PayloadReader(record.payloadJson);
      final qty = reader.quantity.toDouble();
      switch (reader.feedDirection) {
        case FeedDirection.masuk:
          totalIn += qty;
        case FeedDirection.keluar:
          totalOut += qty;
        case FeedDirection.rusak:
          totalDamaged += qty;
        case FeedDirection.penyesuaian:
          break;
      }
      final key = reader.primary.isEmpty ? 'Lainnya' : reader.primary;
      balanceByType[key] = (balanceByType[key] ?? 0) + feedDelta(record);
    }

    return FeedStockSummary(
      totalBalanceKg: balanceByType.values.fold(0, (a, b) => a + b),
      balanceByType: balanceByType,
      totalInKg: totalIn,
      totalOutKg: totalOut,
      totalDamagedKg: totalDamaged,
      history: history,
    );
  }

  static double livestockDelta(OfflineRecord record) {
    final reader = PayloadReader(record.payloadJson);
    final qty = reader.quantity.toDouble();
    return switch (reader.livestockEventType) {
      LivestockEventType.penambahan => qty,
      LivestockEventType.pengurangan => -qty,
      LivestockEventType.kematian => -qty,
      LivestockEventType.catatanKesehatan => 0,
      LivestockEventType.penggunaanPakan => 0,
    };
  }

  static LivestockSummary computeLivestock(List<OfflineRecord> records) {
    final history = _ofType(records, RecordType.livestockEvent);
    final populationByType = <String, double>{};
    var deaths = 0.0, feedUsage = 0.0;
    var healthNotes = 0;

    for (final record in history) {
      final reader = PayloadReader(record.payloadJson);
      final qty = reader.quantity.toDouble();
      switch (reader.livestockEventType) {
        case LivestockEventType.kematian:
          deaths += qty;
        case LivestockEventType.catatanKesehatan:
          healthNotes += 1;
        case LivestockEventType.penggunaanPakan:
          feedUsage += qty;
        case LivestockEventType.penambahan:
        case LivestockEventType.pengurangan:
          break;
      }
      final key = reader.primary.isEmpty ? 'Lainnya' : reader.primary;
      populationByType[key] =
          (populationByType[key] ?? 0) + livestockDelta(record);
    }

    return LivestockSummary(
      totalPopulation: populationByType.values.fold(0, (a, b) => a + b),
      populationByType: populationByType,
      totalDeaths: deaths,
      healthNotes: healthNotes,
      feedUsageKg: feedUsage,
      history: history,
    );
  }

  static double savingsDelta(OfflineRecord record) {
    final reader = PayloadReader(record.payloadJson);
    final amount = reader.quantity.toDouble();
    return reader.savingsDirection == SavingsDirection.setor ? amount : -amount;
  }

  static SavingsLoanSummary computeSavingsLoan(List<OfflineRecord> records) {
    final savingsHistory = _ofType(records, RecordType.savingsTransaction);
    final loanHistory = _ofType(records, RecordType.loanRepayment);
    final savingsByMember = <String, double>{};
    final repaymentsByMember = <String, double>{};
    var deposits = 0.0, withdrawals = 0.0, repayments = 0.0;

    for (final record in savingsHistory) {
      final reader = PayloadReader(record.payloadJson);
      final amount = reader.quantity.toDouble();
      if (reader.savingsDirection == SavingsDirection.setor) {
        deposits += amount;
      } else {
        withdrawals += amount;
      }
      final member = reader.primary.isEmpty ? 'Tanpa Nama' : reader.primary;
      savingsByMember[member] =
          (savingsByMember[member] ?? 0) + savingsDelta(record);
    }

    for (final record in loanHistory) {
      final reader = PayloadReader(record.payloadJson);
      final amount = reader.quantity.toDouble();
      repayments += amount;
      final member = reader.primary.isEmpty ? 'Tanpa Nama' : reader.primary;
      repaymentsByMember[member] =
          (repaymentsByMember[member] ?? 0) + amount;
    }

    return SavingsLoanSummary(
      savingsBalance: deposits - withdrawals,
      totalDeposits: deposits,
      totalWithdrawals: withdrawals,
      totalRepayments: repayments,
      savingsByMember: savingsByMember,
      repaymentsByMember: repaymentsByMember,
      savingsHistory: savingsHistory,
      loanHistory: loanHistory,
    );
  }

  static SyncDelaySummary computeSyncDelays(List<OfflineRecord> records) {
    final entries = <SyncDelayEntry>[];
    for (final record in records) {
      final uploadedAt = record.uploadedAt;
      if (record.syncStatus != SyncStatus.synced || uploadedAt == null) {
        continue;
      }
      var delay = uploadedAt.difference(record.recordedAt);
      if (delay.isNegative) delay = Duration.zero;
      entries.add(SyncDelayEntry(record: record, delay: delay));
    }
    entries.sort((a, b) => b.record.recordedAt.compareTo(a.record.recordedAt));

    if (entries.isEmpty) {
      return const SyncDelaySummary(
        entries: [],
        averageDelay: Duration.zero,
        maxDelay: Duration.zero,
      );
    }
    final totalMs = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.delay.inMilliseconds,
    );
    final maxMs = entries
        .map((entry) => entry.delay.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);
    return SyncDelaySummary(
      entries: entries,
      averageDelay: Duration(milliseconds: totalMs ~/ entries.length),
      maxDelay: Duration(milliseconds: maxMs),
    );
  }
}
