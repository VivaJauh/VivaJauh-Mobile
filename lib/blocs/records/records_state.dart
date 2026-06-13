import 'package:equatable/equatable.dart';

import '../../models/models.dart';

class RecordsNotice extends Equatable {
  const RecordsNotice({
    required this.id,
    required this.message,
    this.isError = false,
  });

  final int id;
  final String message;
  final bool isError;

  @override
  List<Object?> get props => [id, message, isError];
}

class RecordsState extends Equatable {
  const RecordsState({
    this.records = const [],
    this.online = true,
    this.syncing = false,
    this.notice,
  });

  final List<OfflineRecord> records;
  final bool online;
  final bool syncing;
  final RecordsNotice? notice;

  RecordsState copyWith({
    List<OfflineRecord>? records,
    bool? online,
    bool? syncing,
    RecordsNotice? notice,
  }) =>
      RecordsState(
        records: records ?? this.records,
        online: online ?? this.online,
        syncing: syncing ?? this.syncing,
        notice: notice ?? this.notice,
      );

  @override
  List<Object?> get props => [records, online, syncing, notice];
}
