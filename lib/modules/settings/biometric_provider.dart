import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/services/biometric_service.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

class BiometricNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  BiometricNotifier(this._repository) : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    state = await _repository.isBiometricEnabled();
  }

  Future<void> toggle(bool enabled) async {
    await _repository.setBiometricEnabled(enabled);
    state = enabled;
  }
}

final biometricEnabledProvider = StateNotifierProvider<BiometricNotifier, bool>((ref) {
  return BiometricNotifier(ref.watch(settingsRepositoryProvider));
});
