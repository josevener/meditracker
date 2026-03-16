class Medication {
  final int? id;
  final String name;
  final String? dosage;
  final int frequencyPerDay;
  final String startDate;
  final String? endDate;
  final List<Schedule> schedules;

  Medication({
    this.id,
    required this.name,
    this.dosage,
    required this.frequencyPerDay,
    required this.startDate,
    this.endDate,
    this.schedules = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequencyPerDay: json['frequency_per_day'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      schedules: (json['schedules'] as List? ?? [])
          .map((s) => Schedule.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency_per_day': frequencyPerDay,
      'start_date': startDate,
      'end_date': endDate,
      'schedules': schedules.map((s) => s.timeOfDay).toList(), // Backend expects array of strings for create/update
    };
  }
}

class Schedule {
  final int? id;
  final int? medicationId;
  final String timeOfDay;

  Schedule({
    this.id,
    this.medicationId,
    required this.timeOfDay,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      medicationId: json['medication_id'],
      timeOfDay: json['time_of_day'],
    );
  }
}
