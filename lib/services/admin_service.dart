import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class AdminService {
  const AdminService({required this.baseUrl});

  final String baseUrl;

  Future<List<OfflineRecord>> verificationQueue(AuthSession session) async {
    final data = await _get(session, '/verification/queue');
    return (data as List<dynamic>)
        .map(
          (item) =>
              OfflineRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> verifyRecord(
    AuthSession session,
    String id,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/verification/records/$id'),
      headers: _headers(session),
      body: jsonEncode({'verification_status': status}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Verifikasi gagal');
    }
  }

  Future<Map<String, dynamic>> reportSummary(AuthSession session) async =>
      Map<String, dynamic>.from(await _get(session, '/reports/summary') as Map);
  Future<Map<String, dynamic>> portfolio(AuthSession session) async =>
      Map<String, dynamic>.from(
        await _get(session, '/reports/portfolio') as Map,
      );
  Future<List<OfflineRecord>> syncItems(AuthSession session) async {
    final data = await _get(session, '/sync/items');
    return (data as List<dynamic>)
        .map(
          (item) =>
              OfflineRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<String> exportFile(
    AuthSession session,
    String type,
    String format,
  ) async {
    final path = type == 'portfolio'
        ? '/reports/portfolio/export.$format'
        : '/reports/summary/export.$format';
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(session),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Export gagal');
    }
    return response.body;
  }

  Future<dynamic> _get(AuthSession session, String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(session),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message']?.toString() ?? 'Request gagal');
    }
    return body['data'];
  }

  Map<String, String> _headers(AuthSession session) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${session.token}',
  };
}
