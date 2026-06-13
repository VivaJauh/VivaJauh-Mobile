import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'local_cache_service.dart';

class FundService {
  const FundService();

  static const _cache = LocalCacheService();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<FundOverview> overview(
    AuthSession session, {
    bool preferCache = false,
    bool allowNetwork = true,
  }) async {
    final cacheKey = _cacheKey(session, 'fund_overview');
    if (preferCache) {
      final cached = await _readCachedOverview(cacheKey);
      if (cached != null) return cached;
    }
    if (!allowNetwork) {
      throw Exception('Data dana offline belum tersedia');
    }

    try {
      final data = await _request(session, 'GET', '/funds/overview');
      await _cache.putJson(cacheKey, data);
      return FundOverview.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      final cached = await _readCachedOverview(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<FundOverview?> _readCachedOverview(String cacheKey) async {
    final data = await _cache.getJson<Map<String, dynamic>>(cacheKey);
    if (data == null) return null;
    return FundOverview.fromJson(Map<String, dynamic>.from(data as Map));
  }

  String _cacheKey(AuthSession session, String name) {
    final scope = session.tenantId ?? session.userId;
    return '$name:${session.userId}:$scope';
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
      _ => await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: _headers(session),
      ),
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
