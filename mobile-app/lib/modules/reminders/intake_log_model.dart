class IntakeLog {
  final int? id;
  final int medicationId;
  final String medicationName;
  final String scheduledTime;
  final String? takenAt;
  final String date;
  final String status;

  IntakeLog({
    this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenAt,
    required this.date,
    required this.status,
  });

  factory IntakeLog.fromJson(Map<String, dynamic> json) {
    return IntakeLog(
      id: json['id'],
      medicationId: json['medication_id'],
      medicationName: json['medication_name'] ?? '',
      scheduledTime: json['scheduled_time'],
      takenAt: json['taken_at'],
      date: json['date'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime,
      'taken_at': takenAt,
      'date': date,
      'status': status,
    };
  }
}
