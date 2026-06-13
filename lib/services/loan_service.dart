import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'local_cache_service.dart';

class LoanService {
  const LoanService();

  static const _cache = LocalCacheService();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<List<LoanApplication>> list(
    AuthSession session, {
    LoanStatus? status,
    bool preferCache = false,
    bool allowNetwork = true,
  }) async {
    final query = status != null ? '?status=${status.apiValue}' : '';
    final cacheKey = _loanListCacheKey(session, status);
    if (preferCache) {
      final cached = await _readCachedLoanList(cacheKey);
      if (cached != null) return cached;
    }
    if (!allowNetwork) return const <LoanApplication>[];

    try {
      final data = await _request(session, 'GET', '/loans$query');
      await _cache.putJson(cacheKey, data);
      return _parseLoanList(data);
    } catch (_) {
      final cached = await _readCachedLoanList(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<LoanApplication>?> _readCachedLoanList(String cacheKey) async {
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached == null) return null;
    return _parseLoanList(cached);
  }

  List<LoanApplication> _parseLoanList(Object? data) {
    return (data as List<dynamic>)
        .map(
          (item) =>
              LoanApplication.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  String _loanListCacheKey(AuthSession session, LoanStatus? status) {
    final scope = session.tenantId ?? session.userId;
    final statusKey = status?.apiValue ?? 'all';
    return 'loan_applications:${session.userId}:$scope:$statusKey';
  }

  Future<LoanApplication> getById(AuthSession session, String id) async {
    final data = await _request(session, 'GET', '/loans/$id');
    return LoanApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LoanAuditTrail> auditTrail(AuthSession session, String id) async {
    final data = await _request(session, 'GET', '/loans/$id/history');
    return LoanAuditTrail.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LoanApplication> create(
    AuthSession session, {
    required String applicantName,
    required String targetKoperasi,
    required num requestedAmount,
    required int tenureMonths,
    String? applicantMemberId,
    String? purpose,
  }) async {
    final data = await _request(
      session,
      'POST',
      '/loans',
      body: {
        'applicant_name': applicantName,
        'applicant_member_id': applicantMemberId,
        'target_koperasi': targetKoperasi,
        'requested_amount': requestedAmount,
        'purpose': purpose,
        'tenure_months': tenureMonths,
      },
    );
    return LoanApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LoanRecommendation> generateRecommendation(
    AuthSession session,
    String id,
  ) async {
    final data = await _request(session, 'POST', '/loans/$id/recommendation');
    return LoanRecommendation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LoanApplication> approve(
    AuthSession session,
    String id,
    String reviewNote,
  ) async {
    final data = await _request(
      session,
      'PATCH',
      '/loans/$id/approve',
      body: {'review_note': reviewNote},
    );
    return LoanApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LoanApplication> reject(
    AuthSession session,
    String id,
    String reviewNote,
  ) async {
    final data = await _request(
      session,
      'PATCH',
      '/loans/$id/reject',
      body: {'review_note': reviewNote},
    );
    return LoanApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<dynamic> _request(
    AuthSession session,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.token}',
    };

    try {
      final response = switch (method) {
        'POST' => await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'PATCH' => await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        _ => await http.get(uri, headers: headers),
      };

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded['message']?.toString() ?? 'Permintaan gagal');
      }
      return decoded['data'];
    } on FormatException {
      throw Exception('Respons server tidak valid');
    } on http.ClientException {
      throw Exception('Server tidak bisa dihubungi');
    }
  }
}
