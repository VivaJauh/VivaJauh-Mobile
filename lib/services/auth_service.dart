import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

class AuthService {
  AuthService({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const _baseUrl =
      'https://vivajauh-be-production.up.railway.app/api/v1';
  static const _sessionKey = 'vivajauh.auth.session';
  static const _onboardingKey = 'vivajauh.onboarding.completed';
  static const _deviceIdKey = 'vivajauh.device.id';

  bool hasCompletedOnboarding() =>
      _preferences.getBool(_onboardingKey) ?? false;

  Future<void> completeOnboarding() =>
      _preferences.setBool(_onboardingKey, true);

  Future<AuthSession?> restoreSession() async {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<AuthSession> login(String identifier, String password) async {
    final session = await _postAuth('/auth/login', {
      'identifier': identifier,
      'password': password,
      'device_id': await _getDeviceId(),
    });
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _postAuth('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'device_id': await _getDeviceId(),
    });
    await _saveSession(session);
    return session;
  }

  Future<void> logout() => _preferences.remove(_sessionKey);

  Future<AuthSession> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(body['message']?.toString() ?? 'Request gagal');
      }
      return AuthSession.fromJson(body['data'] as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception('Koneksi ke server timeout. Coba lagi nanti.');
    } on SocketException {
      throw Exception(
        'Server tidak bisa dihubungi. Pastikan koneksi internet aktif.',
      );
    } on http.ClientException {
      throw Exception(
        'Server tidak bisa dihubungi. Pastikan koneksi internet aktif.',
      );
    } on FormatException {
      throw Exception('Response server tidak valid.');
    }
  }

  Future<String> _getDeviceId() async {
    final existing = _preferences.getString(_deviceIdKey);
    if (existing != null) return existing;
    final value = const Uuid().v4();
    await _preferences.setString(_deviceIdKey, value);
    return value;
  }

  Future<void> _saveSession(AuthSession session) =>
      _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
}
