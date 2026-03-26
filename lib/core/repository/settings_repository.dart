import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/database/local_db.dart';
import 'package:medtrack_mobile/core/database/database_provider.dart';

class SettingsRepository {
  final AppDatabase db;

  SettingsRepository(this.db);

  Future<String?> getSetting(String key) async {
    final query = db.select(db.appSettings)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  Future<void> saveSetting(String key, String? value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(
            key: Value(key),
            value: Value(value),
          ),
        );
  }

  // Helper methods
  Future<bool> isRemindersEnabled() async {
    final val = await getSetting('reminders_enabled');
    return val == 'true';
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    await saveSetting('reminders_enabled', enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await getSetting('biometric_enabled');
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await saveSetting('biometric_enabled', enabled.toString());
  }

  Future<String?> getUserPin() async {
    return await getSetting('user_pin');
  }

  Future<void> setUserPin(String? pin) async {
    await saveSetting('user_pin', pin);
  }

  Future<bool> isOnboardingCompleted() async {
    final val = await getSetting('onboarding_completed');
    return val == 'true';
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await saveSetting('onboarding_completed', completed.toString());
  }
}

final settingsRepositoryProvider = Provider((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});
