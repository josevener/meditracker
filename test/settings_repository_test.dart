import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:medtrack_mobile/core/database/local_db.dart';
import 'package:medtrack_mobile/core/repository/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repository = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsRepository Tests', () {
    test('should save and retrieve reminders enabled setting', () async {
      await repository.setRemindersEnabled(true);
      expect(await repository.isRemindersEnabled(), true);

      await repository.setRemindersEnabled(false);
      expect(await repository.isRemindersEnabled(), false);
    });

    test('should save and retrieve biometric enabled setting', () async {
      await repository.setBiometricEnabled(true);
      expect(await repository.isBiometricEnabled(), true);

      await repository.setBiometricEnabled(false);
      expect(await repository.isBiometricEnabled(), false);
    });

    test('should save and retrieve user pin', () async {
      const pin = '123456';
      await repository.setUserPin(pin);
      expect(await repository.getUserPin(), pin);

      await repository.setUserPin(null);
      expect(await repository.getUserPin(), isNull);
    });

    test('should save and retrieve onboarding completed setting', () async {
      await repository.setOnboardingCompleted(true);
      expect(await repository.isOnboardingCompleted(), true);

      await repository.setOnboardingCompleted(false);
      expect(await repository.isOnboardingCompleted(), false);
    });

    test('should return default values when setting not found', () async {
      expect(await repository.isRemindersEnabled(), false);
      expect(await repository.isBiometricEnabled(), false);
      expect(await repository.getUserPin(), isNull);
      expect(await repository.isOnboardingCompleted(), false);
    });
  });
}
