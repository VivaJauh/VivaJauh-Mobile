import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const _onboardingKey = 'vivajauh.onboarding.completed';

  bool hasCompletedOnboarding() =>
      _preferences.getBool(_onboardingKey) ?? false;

  Future<void> completeOnboarding() =>
      _preferences.setBool(_onboardingKey, true);
}
