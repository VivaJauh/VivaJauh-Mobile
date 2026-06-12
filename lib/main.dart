import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/pages.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(VivaJauhApp(onboardingService: OnboardingService(preferences: prefs)));
}

class VivaJauhApp extends StatefulWidget {
  const VivaJauhApp({required this.onboardingService, super.key});

  final OnboardingService onboardingService;

  @override
  State<VivaJauhApp> createState() => _VivaJauhAppState();
}

class _VivaJauhAppState extends State<VivaJauhApp> {
  late bool onboarded;

  @override
  void initState() {
    super.initState();
    onboarded = widget.onboardingService.hasCompletedOnboarding();
  }

  Future<void> completeOnboarding() async {
    await widget.onboardingService.completeOnboarding();
    if (mounted) setState(() => onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VivaJauh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: onboarded
          ? const Scaffold(
              body: Center(child: Text('Login coming soon')),
            )
          : OnboardingPage(onCompleted: completeOnboarding),
    );
  }
}
