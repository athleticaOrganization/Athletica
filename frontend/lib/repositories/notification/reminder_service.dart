import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/notification/reminder_model.dart';

class ReminderService {
  Future<List<ReminderModel>> getReminders() async {
    final response = await ApiClient.dio.get('reminders/');
    final data = response.data as List<dynamic>;
    return data.map((json) => ReminderModel.fromJson(json)).toList();
  }

  Future<ReminderModel> createReminder({
    required String activityType,
    required DateTime remindAt,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.post(
      'reminders/',
      data: {
        'activity_type': activityType,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'is_active': isActive,
      },
    );
    return ReminderModel.fromJson(response.data);
  }

  Future<ReminderModel> updateReminder(
    int id, {
    String? activityType,
    DateTime? remindAt,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (activityType != null) payload['activity_type'] = activityType;
    if (remindAt != null) {
      payload['remind_at'] = remindAt.toUtc().toIso8601String();
    }
    if (isActive != null) payload['is_active'] = isActive;

    final response = await ApiClient.dio.put('reminders/$id/', data: payload);
    return ReminderModel.fromJson(response.data);
  }

  Future<void> deleteReminder(int id) async {
    await ApiClient.dio.delete('reminders/$id/');
  }

  Future<List<ReminderModel>> getDueReminders() async {
    final response = await ApiClient.dio.get('reminders/due/');
    final data = response.data as List<dynamic>;
    // Debugging: print to console the raw due reminders
    try {
      // ignore: avoid_print
      print('ReminderService.getDueReminders -> count=${data.length}');
      for (final item in data) {
        // ignore: avoid_print
        print('  due: ${item}');
      }
    } catch (_) {}
    return data.map((json) => ReminderModel.fromJson(json)).toList();
  }
}
