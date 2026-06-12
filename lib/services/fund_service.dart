import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class FundService {
  const FundService();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<FundOverview> overview(AuthSession session) async {
    final data = await _request(session, 'GET', '/funds/overview');
    return FundOverview.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<FundItem> recordPayment(
    AuthSession session, {
    required String memberId,
    required CooperativeFundType fundType,
    required double amount,
    String? periodKey,
    String? note,
  }) async {
    final data = await _request(
      session,
      'POST',
      '/funds/payments',
      body: {
        'member_id': memberId,
        'fund_type': fundType.apiValue,
        'period_key': periodKey,
        'amount': amount,
        'note': note,
      },
    );
    return FundItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<dynamic> _request(
    AuthSession session,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = switch (method) {
      'POST' => await http.post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(session),
          body: jsonEncode(body ?? {}),
        ),
      _ => await http.get(Uri.parse('$_baseUrl$path'), headers: _headers(session)),
    };

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message']?.toString() ?? 'Permintaan gagal');
    }
    return decoded['data'];
  }

  Map<String, String> _headers(AuthSession session) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.token}',
      };
}
