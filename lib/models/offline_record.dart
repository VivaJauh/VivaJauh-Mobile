import 'dart:convert';

import 'record_enums.dart';

class OfflineRecord {
  const OfflineRecord({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.recordType,
    required this.payloadJson,
    required this.syncStatus,
    required this.idempotencyKey,
    required this.recordedAt,
    this.uploadedAt,
    this.errorMessage,
    this.verificationStatus = VerificationStatus.unverified,
  });

  final String id;
  final String userId;
  final String deviceId;
  final RecordType recordType;
  final Map<String, dynamic> payloadJson;
  final SyncStatus syncStatus;
  final String idempotencyKey;
  final DateTime recordedAt;
  final DateTime? uploadedAt;
  final String? errorMessage;
  final VerificationStatus verificationStatus;

  OfflineRecord copyWith({
    RecordType? recordType,
    Map<String, dynamic>? payloadJson,
    SyncStatus? syncStatus,
    String? idempotencyKey,
    DateTime? uploadedAt,
    String? errorMessage,
    VerificationStatus? verificationStatus,
  }) =>
      OfflineRecord(
        id: id,
        userId: userId,
        deviceId: deviceId,
        recordType: recordType ?? this.recordType,
        payloadJson: payloadJson ?? this.payloadJson,
        syncStatus: syncStatus ?? this.syncStatus,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        recordedAt: recordedAt,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        verificationStatus: verificationStatus ?? this.verificationStatus,
      );

  factory OfflineRecord.fromJson(Map<String, dynamic> json) => OfflineRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        deviceId: json['device_id'] as String,
        recordType: RecordTypeX.fromApiValue(json['record_type'] as String),
        payloadJson: json['payload_json'] is String
            ? jsonDecode(json['payload_json'] as String) as Map<String, dynamic>
            : Map<String, dynamic>.from(json['payload_json'] as Map),
        syncStatus: SyncStatusX.fromApiValue(
          json['sync_status'] as String? ?? 'pending',
        ),
        idempotencyKey: json['idempotency_key'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        uploadedAt: json['uploaded_at'] == null
            ? null
            : DateTime.parse(json['uploaded_at'] as String),
        errorMessage: json['error_message'] as String?,
        verificationStatus: VerificationStatusX.fromApiValue(
          json['verification_status'] as String? ?? 'unverified',
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'record_type': recordType.apiValue,
        'payload_json': payloadJson,
        'sync_status': syncStatus.apiValue,
        'idempotency_key': idempotencyKey,
        'recorded_at': recordedAt.toIso8601String(),
        'uploaded_at': uploadedAt?.toIso8601String(),
        'error_message': errorMessage,
        'verification_status': verificationStatus.apiValue,
      };
}
