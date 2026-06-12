import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/models.dart';
import 'pages/pages.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  var loading = true;
  var authLoading = false;
  var onboarded = false;
  String? errorMessage;
  AuthSession? session;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final completed = widget.authService.hasCompletedOnboarding();
    final restored = await widget.authService.restoreSession();
    if (!mounted) return;
    setState(() {
      onboarded = completed;
      session = restored;
      loading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    await widget.authService.completeOnboarding();
    if (mounted) setState(() => onboarded = true);
  }

  Future<void> _login(String identifier, String password) async {
    setState(() {
      authLoading = true;
      errorMessage = null;
    });
    try {
      final s = await widget.authService.login(identifier, password);
      if (mounted) setState(() => session = s);
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => authLoading = false);
    }
  }

  Future<void> _register(String name, String email, String password) async {
    setState(() {
      authLoading = true;
      errorMessage = null;
    });
    try {
      final s = await widget.authService.register(
        name: name,
        email: email,
        password: password,
      );
      if (mounted) setState(() => session = s);
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => authLoading = false);
    }
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (mounted) setState(() => session = null);
  }

  Widget _buildHome() {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!onboarded) {
      return OnboardingPage(onCompleted: _completeOnboarding);
    }
    if (session == null) {
      return LoginPage(
        loading: authLoading,
        errorMessage: errorMessage,
        onLogin: _login,
        onRegister: _register,
      );
    }
    // TODO: ganti dengan DashboardPage saat sudah siap
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Halo, ${session!.name}'),
            const SizedBox(height: 12),
            TextButton(onPressed: _logout, child: const Text('Logout')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VivaJauh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _buildHome(),
    );
  }
}
