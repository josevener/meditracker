import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_model.dart';
import 'package:medtrack_mobile/core/database/local_db.dart' hide Medication;
import 'package:medtrack_mobile/core/repository/medication_repository.dart';
import 'package:medtrack_mobile/services/medication_service.dart';
import 'package:medtrack_mobile/core/api/api_client.dart';

import 'package:medtrack_mobile/services/sync_service.dart';

final medicationServiceProvider = Provider((ref) => MedicationService(ref.watch(apiClientProvider)));

final databaseProvider = Provider((ref) => AppDatabase());

final medicationRepositoryProvider = Provider((ref) => MedicationRepository(
      ref.watch(databaseProvider),
    ));

final syncServiceProvider = Provider((ref) => SyncService(
      ref.watch(databaseProvider),
      ref.watch(medicationServiceProvider),
    ));

class MedicationListNotifier extends StateNotifier<AsyncValue<List<Medication>>> {
  final MedicationRepository _repository;

  MedicationListNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final meds = await _repository.getAllMedications();
      state = AsyncValue.data(meds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      await _repository.addMedication(medication);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeMedication(int id) async {
    try {
      await _repository.deleteMedication(id);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }
}

final medicationListProvider = StateNotifierProvider<MedicationListNotifier, AsyncValue<List<Medication>>>((ref) {
  return MedicationListNotifier(ref.watch(medicationRepositoryProvider));
});

final todayLogsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(medicationRepositoryProvider);
  final today = DateTime.now().toString().split(' ')[0];
  return repo.getLogsForDate(today);
});
