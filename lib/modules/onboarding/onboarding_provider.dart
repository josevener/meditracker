import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';

final onboardingStatusProvider = StateNotifierProvider<OnboardingStatusNotifier, bool?>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return OnboardingStatusNotifier(repository);
});

class OnboardingStatusNotifier extends StateNotifier<bool?> {
  final SettingsRepository _repository;

  OnboardingStatusNotifier(this._repository) : super(null) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    state = await _repository.isOnboardingCompleted();
  }

  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted(true);
    state = true;
  }
}
