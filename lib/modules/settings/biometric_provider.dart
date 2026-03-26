import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medtrack_mobile/services/biometric_service.dart';

final biometricServiceProvider = Provider((ref) => BiometricService());

class BiometricNotifier extends StateNotifier<bool> {
  BiometricNotifier() : super(false) {
    _loadPreference();
  }

  static const _prefKey = 'biometric_enabled';

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    state = enabled;
  }
}

final biometricEnabledProvider = StateNotifierProvider<BiometricNotifier, bool>((ref) {
  return BiometricNotifier();
});
