import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'record_service.dart';

class SyncService {
  SyncService({required RecordService recordService})
    : _recordService = recordService;

  final RecordService _recordService;

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<List<OfflineRecord>> retryRecord(String token, String id) async {
    final records = await _recordService.loadRecords();
    final target = records.where((r) => r.id == id).firstOrNull;
    if (target == null) return records;
    if (target.syncStatus == SyncStatus.failed ||
        target.syncStatus == SyncStatus.conflict) {
      await _recordService.replaceRecord(
        _cleanRecord(target, syncStatus: SyncStatus.pending),
      );
    }
    return syncAll(token);
  }

  Future<List<OfflineRecord>> syncAll(String token) async {
    await syncPending(token);
    return pullSynced(token);
  }

  Future<List<OfflineRecord>> syncPending(String token) async {
    final records = await _recordService.loadRecords();
    final pending = records
        .where((r) => r.syncStatus == SyncStatus.pending)
        .toList();
    if (pending.isEmpty) return records;

    for (final record in pending) {
      await _recordService.replaceRecord(
        _cleanRecord(record, syncStatus: SyncStatus.syncing),
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'items': pending.map((r) => r.toJson()).toList()}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Sync failed ${response.statusCode}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results =
          (body['data'] as Map<String, dynamic>)['results'] as List<dynamic>;
      final byId = {
        for (final r in results.cast<Map<String, dynamic>>())
          r['local_id'] as String: r,
      };

      final latest = await _recordService.loadRecords();
      final updated = latest.map((record) {
        final result = byId[record.id];
        if (result == null) return record;
        if (result['status'] == 'failed') {
          return record.copyWith(
            syncStatus: SyncStatus.failed,
            errorMessage: result['error_code'] as String?,
          );
        }
        return _cleanRecord(
          record,
          syncStatus: SyncStatus.synced,
          uploadedAt: DateTime.tryParse(result['uploaded_at'] as String? ?? ''),
          verificationStatus: VerificationStatusX.fromApiValue(
            result['verification_status'] as String? ?? 'unverified',
          ),
        );
      }).toList();
      await _recordService.saveRecords(updated);
      return updated;
    } catch (error) {
      final latest = await _recordService.loadRecords();
      final updated = latest.map((record) {
        if (pending.any((p) => p.id == record.id)) {
          return record.copyWith(
            syncStatus: SyncStatus.pending,
            errorMessage: error.toString(),
          );
        }
        return record;
      }).toList();
      await _recordService.saveRecords(updated);
      return updated;
    }
  }

  Future<List<OfflineRecord>> pullSynced(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sync/items'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body);
      throw Exception(message ?? 'Gagal mengambil data sinkronisasi');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    final remoteRecords = data
        .map((item) => _remoteRecord(Map<String, dynamic>.from(item as Map)))
        .toList();

    if (remoteRecords.isEmpty) {
      return _recordService.loadRecords();
    }

    final localRecords = await _recordService.loadRecords();
    final byKey = <String, OfflineRecord>{
      for (final record in localRecords) _recordKey(record): record,
    };

    for (final record in remoteRecords) {
      byKey[_recordKey(record)] = record;
    }

    final merged = byKey.values.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    await _recordService.saveRecords(merged);
    return merged;
  }

  OfflineRecord _remoteRecord(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['id'] = (normalized['local_id'] ?? normalized['id']).toString();
    return _cleanRecord(
      OfflineRecord.fromJson(normalized),
      syncStatus: SyncStatus.synced,
    );
  }

  OfflineRecord _cleanRecord(
    OfflineRecord record, {
    SyncStatus? syncStatus,
    DateTime? uploadedAt,
    VerificationStatus? verificationStatus,
  }) => OfflineRecord(
    id: record.id,
    userId: record.userId,
    deviceId: record.deviceId,
    recordType: record.recordType,
    payloadJson: record.payloadJson,
    syncStatus: syncStatus ?? record.syncStatus,
    idempotencyKey: record.idempotencyKey,
    recordedAt: record.recordedAt,
    uploadedAt: uploadedAt ?? record.uploadedAt,
    verificationStatus: verificationStatus ?? record.verificationStatus,
  );

  String _recordKey(OfflineRecord record) => record.idempotencyKey.isNotEmpty
      ? 'idempotency:${record.idempotencyKey}'
      : 'id:${record.id}';

  String? _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
