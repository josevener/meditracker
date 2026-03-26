import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';

class PinNotifier extends StateNotifier<AsyncValue<String?>> {
  final SettingsRepository _repository;

  PinNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final pin = await _repository.getUserPin();
      state = AsyncValue.data(pin);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPin(String pin) async {
    try {
      await _repository.setUserPin(pin);
      state = AsyncValue.data(pin);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removePin() async {
    try {
      await _repository.setUserPin(null);
      state = const AsyncValue.data(null);
    } 
    catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool get isPinSet => state.value != null;
}

final pinProvider = StateNotifierProvider<PinNotifier, AsyncValue<String?>>((ref) {
  return PinNotifier(ref.watch(settingsRepositoryProvider));
});
