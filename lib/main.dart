import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/models.dart';
import 'pages/pages.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(VivaJauhApp(authService: AuthService(preferences: prefs)));
}

class VivaJauhApp extends StatefulWidget {
  const VivaJauhApp({required this.authService, super.key});

  final AuthService authService;

  @override
  State<VivaJauhApp> createState() => _VivaJauhAppState();
}

class _VivaJauhAppState extends State<VivaJauhApp> {
  var _loading = true;
  var _authLoading = false;
  var _onboarded = false;
  String? _errorMessage;
  AuthSession? _session;

  List<OfflineRecord> _records = [];
  bool _syncing = false;
  bool _online = true;

  late final RecordService _recordService;
  late final SyncService _syncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _recordService = RecordService();
    _syncService = SyncService(recordService: _recordService);
    _boot();
    _watchConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _watchConnectivity() {
    Connectivity().checkConnectivity().then((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _online = online);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!mounted) return;
      setState(() => _online = online);
      if (online && _session != null && !_syncing) {
        _sync();
      }
    });
  }

  Future<void> _boot() async {
    final completed = widget.authService.hasCompletedOnboarding();
    final restored = await widget.authService.restoreSession();
    if (!mounted) return;
    setState(() {
      _onboarded = completed;
      _session = restored;
      _loading = false;
    });
    if (restored != null) await _loadRecords();
  }

  Future<void> _loadRecords() async {
    final session = _session;
    if (session == null) return;
    final records = await _recordService.loadRecords(userId: session.userId);
    if (mounted) setState(() => _records = records);
  }

  Future<void> _completeOnboarding() async {
    await widget.authService.completeOnboarding();
    if (mounted) setState(() => _onboarded = true);
  }

  Future<void> _login(String identifier, String password) async {
    setState(() {
      _authLoading = true;
      _errorMessage = null;
    });
    try {
      final s = await widget.authService.login(identifier, password);
      if (mounted) {
        setState(() => _session = s);
        await _loadRecords();
        if (_online) unawaited(_sync());
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _register(String name, String email, String password) async {
    setState(() {
      _authLoading = true;
      _errorMessage = null;
    });
    try {
      final s = await widget.authService.register(
        name: name,
        email: email,
        password: password,
      );
      if (mounted) {
        setState(() => _session = s);
        await _loadRecords();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (mounted) {
      setState(() {
        _session = null;
        _records = [];
      });
    }
  }

  Future<void> _addRecord(RecordType type, Map<String, dynamic> payload) async {
    final sess = _session;
    if (sess == null) return;
    await _recordService.addRecord(
      session: sess,
      recordType: type,
      payloadJson: payload,
    );
    await _loadRecords();
    if (_online && !_syncing) unawaited(_sync());
  }

  Future<void> _updateRecord(
    RecordType type,
    Map<String, dynamic> correctedPayload,
  ) async {
    final sess = _session;
    if (sess == null) return;
    await _recordService.addRecord(
      session: sess,
      recordType: RecordType.correction,
      payloadJson: {
        'corrected_type': type.apiValue,
        ...correctedPayload,
      },
    );
    await _loadRecords();
    if (_online && !_syncing) unawaited(_sync());
  }

  Future<void> _deleteRecord(OfflineRecord record) async {
    final sess = _session;
    if (sess == null) return;
    await _recordService.addRecord(
      session: sess,
      recordType: RecordType.correction,
      payloadJson: {
        'target_id': record.id,
        'target_type': record.recordType.apiValue,
        PayloadKeys.primary: 'Ajukan penghapusan',
        PayloadKeys.quantity: 1,
        PayloadKeys.secondary: '',
        PayloadKeys.note: 'delete_request',
        PayloadKeys.officer: sess.name,
        PayloadKeys.schemaVersion: PayloadKeys.currentSchemaVersion,
      },
    );
    await _loadRecords();
    if (_online && !_syncing) unawaited(_sync());
  }

  Future<void> _sync() async {
    final sess = _session;
    if (sess == null || _syncing || !_online) return;
    setState(() => _syncing = true);
    try {
      final synced = await _syncService.syncPending(sess.token);
      if (synced.isNotEmpty) {
        await _recordService.saveRecords(synced);
      }
      await _loadRecords();
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${synced.length} catatan berhasil disinkronkan'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Sinkronisasi gagal: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _retryRecord(OfflineRecord record) async {
    final updated = OfflineRecord(
      id: record.id,
      userId: record.userId,
      deviceId: record.deviceId,
      recordType: record.recordType,
      payloadJson: record.payloadJson,
      syncStatus: SyncStatus.pending,
      idempotencyKey: record.idempotencyKey,
      recordedAt: record.recordedAt,
      uploadedAt: record.uploadedAt,
      verificationStatus: record.verificationStatus,
    );
    await _recordService.replaceRecord(updated);
    await _loadRecords();
    if (_online && !_syncing) unawaited(_sync());
  }

  Widget _buildHome() {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboarded) {
      return OnboardingPage(onCompleted: _completeOnboarding);
    }
    if (_session == null) {
      return LoginPage(
        loading: _authLoading,
        errorMessage: _errorMessage,
        onLogin: _login,
        onRegister: _register,
      );
    }
    return DashboardPage(
      session: _session!,
      records: _records,
      syncing: _syncing,
      online: _online,
      onLogout: _logout,
      onAddRecord: _addRecord,
      onUpdateRecord: _updateRecord,
      onDeleteRecord: _deleteRecord,
      onSync: _sync,
      onRetryRecord: _retryRecord,
      onRefreshRecords: _loadRecords,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VivaJauh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _scaffoldKey,
      home: _buildHome(),
    );
  }
}
