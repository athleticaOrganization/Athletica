class ReminderModel {
  final int id;
  final String activityType;
  final DateTime remindAt;
  final bool isActive;
  final DateTime? notifiedAt;

  ReminderModel({
    required this.id,
    required this.activityType,
    required this.remindAt,
    required this.isActive,
    this.notifiedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      activityType: json['activity_type'],
      remindAt: DateTime.parse(json['remind_at']).toLocal(),
      isActive: json['is_active'] ?? true,
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      'remind_at': remindAt.toUtc().toIso8601String(),
      'is_active': isActive,
    };
  }
}
