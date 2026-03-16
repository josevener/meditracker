import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinNotifier extends StateNotifier<AsyncValue<String?>> {
  PinNotifier() : super(const AsyncValue.loading()) {
    _loadPin();
  }

  static const _pinKey = 'user_pin';

  Future<void> _loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString(_pinKey);
      state = AsyncValue.data(pin);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
      state = AsyncValue.data(pin);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      state = const AsyncValue.data(null);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool get isPinSet => state.value != null;
}

final pinProvider = StateNotifierProvider<PinNotifier, AsyncValue<String?>>((ref) {
  return PinNotifier();
});
