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
        target.copyWith(syncStatus: SyncStatus.pending, errorMessage: null),
      );
    }
    return syncPending(token);
  }

  Future<List<OfflineRecord>> syncPending(String token) async {
    final records = await _recordService.loadRecords();
    final pending =
        records.where((r) => r.syncStatus == SyncStatus.pending).toList();
    if (pending.isEmpty) return records;

    for (final record in pending) {
      await _recordService.replaceRecord(
        record.copyWith(syncStatus: SyncStatus.syncing),
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': pending.map((r) => r.toJson()).toList(),
        }),
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
        return record.copyWith(
          syncStatus: SyncStatus.synced,
          uploadedAt:
              DateTime.tryParse(result['uploaded_at'] as String? ?? ''),
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
}
