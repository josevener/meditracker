import 'package:medtrack_mobile/core/api/api_client.dart';
import 'package:medtrack_mobile/modules/medications/medication_model.dart';
import 'package:medtrack_mobile/modules/reminders/intake_log_model.dart';

class MedicationService {
  final ApiClient _apiClient;

  MedicationService(this._apiClient);

  Future<List<Medication>> getMedications() async {
    try {
      final response = await _apiClient.dio.get('/medications');
      return (response.data as List)
          .map((m) => Medication.fromJson(m))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Medication> createMedication(Medication medication) async {
    try {
      final response = await _apiClient.dio.post('/medications', data: medication.toJson());
      return Medication.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Medication> updateMedication(Medication medication) async {
    try {
      final response = await _apiClient.dio.put('/medications/${medication.id}', data: medication.toJson());
      return Medication.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _apiClient.dio.delete('/medications/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logIntake(int medicationId, String scheduledTime, String status) async {
    try {
      final date = DateTime.now().toString().split(' ')[0];
      await _apiClient.dio.post('/intake-logs', data: {
        'medication_id': medicationId,
        'scheduled_time': scheduledTime,
        'status': status,
        'date': date,
        'taken_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<IntakeLog>> getDailyLogs(String date) async {
    try {
      final response = await _apiClient.dio.get('/intake-logs', queryParameters: {'date': date});
      return (response.data as List)
          .map((l) => IntakeLog.fromJson(l))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
