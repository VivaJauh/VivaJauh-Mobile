import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'local_db.dart';

class RecordService {
  Future<List<OfflineRecord>> loadRecords({String? userId}) async {
    final db = await LocalDb.open();
    final rows = await db.query(
      'records',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'recorded_at DESC',
    );
    return rows
        .map((row) => OfflineRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addRecord({
    required AuthSession session,
    required RecordType recordType,
    required Map<String, dynamic> payloadJson,
  }) async {
    final db = await LocalDb.open();
    final record = OfflineRecord(
      id: const Uuid().v4(),
      userId: session.userId,
      deviceId: session.deviceId,
      recordType: recordType,
      payloadJson: payloadJson,
      syncStatus: SyncStatus.pending,
      idempotencyKey: const Uuid().v4(),
      recordedAt: DateTime.now(),
    );
    await db.insert('records', _toDb(record),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> replaceRecord(OfflineRecord record) async {
    final db = await LocalDb.open();
    await db.update('records', _toDb(record),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> saveRecords(List<OfflineRecord> records) async {
    final db = await LocalDb.open();
    final batch = db.batch();
    for (final record in records) {
      batch.insert('records', _toDb(record),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _toDb(OfflineRecord record) => {
        'id': record.id,
        'user_id': record.userId,
        'device_id': record.deviceId,
        'record_type': record.recordType.apiValue,
        'payload_json': jsonEncode(record.payloadJson),
        'sync_status': record.syncStatus.apiValue,
        'idempotency_key': record.idempotencyKey,
        'recorded_at': record.recordedAt.toIso8601String(),
        'uploaded_at': record.uploadedAt?.toIso8601String(),
        'error_message': record.errorMessage,
        'verification_status': record.verificationStatus.apiValue,
      };
}
