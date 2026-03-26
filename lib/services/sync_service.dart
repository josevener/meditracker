import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:medtrack_mobile/core/database/local_db.dart';
import 'package:medtrack_mobile/modules/medications/medication_model.dart' as model;
import 'package:medtrack_mobile/services/medication_service.dart';

class SyncService {
  final AppDatabase _db;
  final MedicationService _remoteService;

  SyncService(this._db, this._remoteService);

  Future<void> sync() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    await _pushLocalChanges();
    await _pullRemoteChanges();
  }

  Future<void> _pushLocalChanges() async {
    // 1. Push new/updated medications
    final unsyncedMeds = await (_db.select(_db.medications)
          ..where((t) => t.isSynced.equals(false)))
        .get();

    for (var med in unsyncedMeds) {
      try {
        if (med.isDeleted) {
          if (med.remoteId != null) {
            await _remoteService.deleteMedication(med.remoteId!);
          }
          await (_db.delete(_db.medications)..where((t) => t.id.equals(med.id))).go();
        } else {
          final scheduleRows = await (_db.select(_db.schedules)
                ..where((t) => t.medicationId.equals(med.id) & t.isDeleted.equals(false)))
              .get();

          final medModel = model.Medication(
            id: med.remoteId,
            name: med.name,
            dosage: med.dosage,
            frequencyPerDay: med.frequencyPerDay,
            startDate: med.startDate,
            endDate: med.endDate,
            schedules: scheduleRows.map((s) => model.Schedule(timeOfDay: s.timeOfDay)).toList(),
          );

          model.Medication remoteMed;
          if (med.remoteId == null) {
            remoteMed = await _remoteService.createMedication(medModel);
          } else {
            remoteMed = await _remoteService.updateMedication(medModel);
          }

          // Update local with remote ID and mark as synced
          await (_db.update(_db.medications)..where((t) => t.id.equals(med.id))).write(
                MedicationsCompanion(
                  remoteId: Value(remoteMed.id),
                  isSynced: const Value(true),
                ),
              );
          
          // Mark schedules as synced
          await (_db.update(_db.schedules)..where((t) => t.medicationId.equals(med.id)))
              .write(const SchedulesCompanion(isSynced: Value(true)));
        }
      } catch (e) {
        print('Sync error for med ${med.id}: $e');
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    try {
      final remoteMeds = await _remoteService.getMedications();
      
      for (var remoteMed in remoteMeds) {
        final localMed = await (_db.select(_db.medications)
              ..where((t) => t.remoteId.equals(remoteMed.id!)))
            .getSingleOrNull();

        if (localMed == null) {
          // New from remote
          final localId = await _db.into(_db.medications).insert(MedicationsCompanion.insert(
                remoteId: Value(remoteMed.id),
                name: remoteMed.name,
                dosage: Value(remoteMed.dosage),
                frequencyPerDay: remoteMed.frequencyPerDay,
                startDate: remoteMed.startDate,
                endDate: Value(remoteMed.endDate),
                isSynced: const Value(true),
              ));

          for (var s in remoteMed.schedules) {
            await _db.into(_db.schedules).insert(SchedulesCompanion.insert(
                  remoteId: Value(s.id),
                  medicationId: localId,
                  timeOfDay: s.timeOfDay,
                  isSynced: const Value(true),
                ));
          }
        } else {
          // Conflict resolution: Remote wins for now if local is synced
          if (localMed.isSynced) {
             await (_db.update(_db.medications)..where((t) => t.id.equals(localMed.id))).write(
                MedicationsCompanion(
                  name: Value(remoteMed.name),
                  dosage: Value(remoteMed.dosage),
                  frequencyPerDay: Value(remoteMed.frequencyPerDay),
                  startDate: Value(remoteMed.startDate),
                  endDate: Value(remoteMed.endDate),
                ),
              );
             // Update schedules similarly...
          }
        }
      }
    } catch (e) {
      print('Pull sync error: $e');
    }
  }
}
