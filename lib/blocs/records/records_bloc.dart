import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/record_service.dart';
import '../../services/sync_service.dart';
import 'records_event.dart';
import 'records_state.dart';

export 'records_event.dart';
export 'records_state.dart';

class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  static const _autoSyncInterval = Duration(seconds: 45);

  RecordsBloc({
    required RecordService recordService,
    required SyncService syncService,
    Connectivity? connectivity,
  }) : _recordService = recordService,
       _syncService = syncService,
       _connectivity = connectivity ?? Connectivity(),
       super(const RecordsState()) {
    on<RecordsStarted>(_onStarted);
    on<RecordsCleared>(_onCleared);
    on<RecordsRefreshRequested>(_onRefreshRequested);
    on<RecordAdded>(_onRecordAdded);
    on<RecordCorrectionSubmitted>(_onCorrectionSubmitted);
    on<RecordDeletionRequested>(_onDeletionRequested);
    on<RecordRetryRequested>(_onRetryRequested);
    on<RecordsSyncRequested>(_onSyncRequested);
    on<RecordsConnectivityChanged>(_onConnectivityChanged);

    _connectivity.checkConnectivity().then(_handleConnectivityResults);
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityResults,
    );
  }

  final RecordService _recordService;
  final SyncService _syncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _autoSyncTimer;
  AuthSession? _session;
  int _noticeCounter = 0;

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    if (isClosed) return;
    final online = results.any((r) => r != ConnectivityResult.none);
    add(RecordsConnectivityChanged(online));
  }

  RecordsNotice _notice(String message, {bool isError = false}) =>
      RecordsNotice(id: ++_noticeCounter, message: message, isError: isError);

  Future<List<OfflineRecord>> _load() async {
    final session = _session;
    if (session == null) return const [];
    return _recordService.loadRecords(userId: session.userId);
  }

  Future<void> _onStarted(
    RecordsStarted event,
    Emitter<RecordsState> emit,
  ) async {
    _session = event.session;
    _startAutoSyncWorker();
    emit(state.copyWith(records: await _load()));
    if (state.online) add(const RecordsSyncRequested());
  }

  Future<void> _onCleared(
    RecordsCleared event,
    Emitter<RecordsState> emit,
  ) async {
    _session = null;
    _stopAutoSyncWorker();
    emit(RecordsState(online: state.online));
  }

  Future<void> _onRefreshRequested(
    RecordsRefreshRequested event,
    Emitter<RecordsState> emit,
  ) async {
    emit(state.copyWith(records: await _load()));
  }

  Future<void> _onRecordAdded(
    RecordAdded event,
    Emitter<RecordsState> emit,
  ) async {
    final session = _session;
    if (session == null) return;
    await _recordService.addRecord(
      session: session,
      recordType: event.recordType,
      payloadJson: event.payload,
    );
    emit(state.copyWith(records: await _load()));
    if (state.online && !state.syncing) add(const RecordsSyncRequested());
  }

  Future<void> _onCorrectionSubmitted(
    RecordCorrectionSubmitted event,
    Emitter<RecordsState> emit,
  ) async {
    final session = _session;
    if (session == null) return;
    await _recordService.addRecord(
      session: session,
      recordType: RecordType.correction,
      payloadJson: {
        'corrected_type': event.recordType.apiValue,
        ...event.payload,
      },
    );
    emit(state.copyWith(records: await _load()));
    if (state.online && !state.syncing) add(const RecordsSyncRequested());
  }

  Future<void> _onDeletionRequested(
    RecordDeletionRequested event,
    Emitter<RecordsState> emit,
  ) async {
    final session = _session;
    if (session == null) return;
    await _recordService.addRecord(
      session: session,
      recordType: RecordType.correction,
      payloadJson: {
        'target_id': event.record.id,
        'target_type': event.record.recordType.apiValue,
        PayloadKeys.primary: 'Ajukan penghapusan',
        PayloadKeys.quantity: 1,
        PayloadKeys.secondary: '',
        PayloadKeys.note: 'delete_request',
        PayloadKeys.officer: session.name,
        PayloadKeys.schemaVersion: PayloadKeys.currentSchemaVersion,
      },
    );
    emit(state.copyWith(records: await _load()));
    if (state.online && !state.syncing) add(const RecordsSyncRequested());
  }

  Future<void> _onRetryRequested(
    RecordRetryRequested event,
    Emitter<RecordsState> emit,
  ) async {
    final record = event.record;
    await _recordService.replaceRecord(
      OfflineRecord(
        id: record.id,
        userId: record.userId,
        deviceId: record.deviceId,
        recordType: record.recordType,
        payloadJson: record.payloadJson,
        syncStatus: SyncStatus.pending,
        idempotencyKey: record.idempotencyKey,
        recordedAt: record.recordedAt,
        uploadedAt: record.uploadedAt,
        verificationStatus: record.verificationStatus,
      ),
    );
    emit(state.copyWith(records: await _load()));
    if (state.online && !state.syncing) add(const RecordsSyncRequested());
  }

  Future<void> _onSyncRequested(
    RecordsSyncRequested event,
    Emitter<RecordsState> emit,
  ) async {
    final session = _session;
    if (session == null || state.syncing || !state.online) return;

    emit(state.copyWith(syncing: true));
    try {
      await _syncService.syncAll(session.token);
      final records = await _load();
      emit(
        state.copyWith(
          records: records,
          syncing: false,
          notice: event.silent
              ? state.notice
              : _notice('Sinkronisasi selesai (${records.length} catatan)'),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          syncing: false,
          notice: _notice('Sinkronisasi gagal: $e', isError: true),
        ),
      );
    }
  }

  Future<void> _onConnectivityChanged(
    RecordsConnectivityChanged event,
    Emitter<RecordsState> emit,
  ) async {
    emit(state.copyWith(online: event.online));
    if (event.online && _session != null && !state.syncing) {
      add(const RecordsSyncRequested());
    }
  }

  @override
  Future<void> close() {
    _stopAutoSyncWorker();
    _connectivitySub?.cancel();
    return super.close();
  }

  void _startAutoSyncWorker() {
    _autoSyncTimer ??= Timer.periodic(_autoSyncInterval, (_) {
      if (isClosed || _session == null || !state.online || state.syncing) {
        return;
      }
      add(const RecordsSyncRequested(silent: true));
    });
  }

  void _stopAutoSyncWorker() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
}
