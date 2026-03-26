import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';

class RemindersNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  RemindersNotifier(this._repository) : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    state = await _repository.isRemindersEnabled();
  }

  Future<void> toggle(bool enabled) async {
    await _repository.setRemindersEnabled(enabled);
    state = enabled;
  }
}

final remindersEnabledProvider = StateNotifierProvider<RemindersNotifier, bool>((ref) {
  return RemindersNotifier(ref.watch(settingsRepositoryProvider));
});
