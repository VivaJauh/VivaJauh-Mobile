import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class TenantService {
  const TenantService();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<List<MemberSummary>> members(AuthSession session) async {
    final data = await _get(session, '/tenants/members');
    return (data as List<dynamic>)
        .map(
          (item) =>
              MemberSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<OfflineRecord>> memberRecords(
    AuthSession session,
    String userId,
  ) async {
    final data = await _get(session, '/tenants/members/$userId/records');
    return (data as List<dynamic>)
        .map(
          (item) =>
              OfflineRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<KoperasiSummary>> koperasiSummaries(AuthSession session) async {
    final data = await _get(session, '/tenants/summary');
    return (data as List<dynamic>)
        .map(
          (item) =>
              KoperasiSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<OfflineRecord>> tenantRecords(
    AuthSession session,
    String tenantId,
  ) async {
    final data = await _get(session, '/tenants/$tenantId/records');
    return (data as List<dynamic>)
        .map(
          (item) =>
              OfflineRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<dynamic> _get(AuthSession session, String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.token}',
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message']?.toString() ?? 'Permintaan gagal');
    }
    return body['data'];
  }
}
