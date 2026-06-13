import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'local_cache_service.dart';

class TenantService {
  const TenantService();

  static const _cache = LocalCacheService();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://vivajauh-be-production.up.railway.app/api/v1';

  Future<List<MemberSummary>> members(
    AuthSession session, {
    bool preferCache = false,
    bool allowNetwork = true,
  }) => _cachedList(
    session: session,
    path: '/tenants/members',
    cacheName: 'tenant_members',
    preferCache: preferCache,
    allowNetwork: allowNetwork,
    parser: MemberSummary.fromJson,
  );

  Future<List<OfflineRecord>> memberRecords(
    AuthSession session,
    String userId, {
    bool preferCache = false,
    bool allowNetwork = true,
  }) => _cachedList(
    session: session,
    path: '/tenants/members/$userId/records',
    cacheName: 'tenant_member_records:$userId',
    preferCache: preferCache,
    allowNetwork: allowNetwork,
    parser: OfflineRecord.fromJson,
  );

  Future<List<KoperasiSummary>> koperasiSummaries(
    AuthSession session, {
    bool preferCache = false,
    bool allowNetwork = true,
  }) => _cachedList(
    session: session,
    path: '/tenants/summary',
    cacheName: 'tenant_summaries',
    preferCache: preferCache,
    allowNetwork: allowNetwork,
    parser: KoperasiSummary.fromJson,
  );

  Future<List<OfflineRecord>> tenantRecords(
    AuthSession session,
    String tenantId, {
    bool preferCache = false,
    bool allowNetwork = true,
  }) => _cachedList(
    session: session,
    path: '/tenants/$tenantId/records',
    cacheName: 'tenant_records:$tenantId',
    preferCache: preferCache,
    allowNetwork: allowNetwork,
    parser: OfflineRecord.fromJson,
  );

  Future<List<T>> _cachedList<T>({
    required AuthSession session,
    required String path,
    required String cacheName,
    required T Function(Map<String, dynamic>) parser,
    required bool preferCache,
    required bool allowNetwork,
  }) async {
    final cacheKey = _cacheKey(session, cacheName);
    if (preferCache) {
      final cached = await _readCachedList(cacheKey, parser);
      if (cached != null) return cached;
    }
    if (!allowNetwork) return <T>[];

    try {
      final data = await _get(session, path);
      await _cache.putJson(cacheKey, data);
      return _parseList(data, parser);
    } catch (_) {
      final cached = await _readCachedList(cacheKey, parser);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<T>?> _readCachedList<T>(
    String cacheKey,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final cached = await _cache.getJson<List<dynamic>>(cacheKey);
    if (cached == null) return null;
    return _parseList(cached, parser);
  }

  List<T> _parseList<T>(Object? data, T Function(Map<String, dynamic>) parser) {
    return (data as List<dynamic>)
        .map((item) => parser(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  String _cacheKey(AuthSession session, String name) {
    final scope = session.tenantId ?? session.userId;
    return '$name:${session.userId}:$scope';
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
