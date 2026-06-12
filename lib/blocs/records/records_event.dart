import 'package:equatable/equatable.dart';

import '../../models/models.dart';

sealed class RecordsEvent extends Equatable {
  const RecordsEvent();

  @override
  List<Object?> get props => [];
}

class RecordsStarted extends RecordsEvent {
  const RecordsStarted(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session.userId];
}

class RecordsCleared extends RecordsEvent {
  const RecordsCleared();
}

class RecordsRefreshRequested extends RecordsEvent {
  const RecordsRefreshRequested();
}

class RecordAdded extends RecordsEvent {
  const RecordAdded({required this.recordType, required this.payload});

  final RecordType recordType;
  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [recordType, payload];
}

class RecordCorrectionSubmitted extends RecordsEvent {
  const RecordCorrectionSubmitted({
    required this.recordType,
    required this.payload,
  });

  final RecordType recordType;
  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [recordType, payload];
}

class RecordDeletionRequested extends RecordsEvent {
  const RecordDeletionRequested(this.record);

  final OfflineRecord record;

  @override
  List<Object?> get props => [record.id];
}

class RecordRetryRequested extends RecordsEvent {
  const RecordRetryRequested(this.record);

  final OfflineRecord record;

  @override
  List<Object?> get props => [record.id];
}

class RecordsSyncRequested extends RecordsEvent {
  const RecordsSyncRequested();
}

class RecordsConnectivityChanged extends RecordsEvent {
  const RecordsConnectivityChanged(this.online);

  final bool online;

  @override
  List<Object?> get props => [online];
}
