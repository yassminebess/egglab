// lib/services/flip_eggs_reminder.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class FlipEggsReminder {
  static const String _lastFlipKey = 'last_flip_time_';
  static const Duration flipInterval = Duration(hours: 8);

  /// Gets the next flip time for a batch
  static Future<DateTime> getNextFlipTime(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFlipTime = prefs.getInt(_lastFlipKey + batchId);

    if (lastFlipTime != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastFlipTime)
          .add(flipInterval);
    } else {
      // If no last flip time is recorded, return 8 hours from now
      return DateTime.now().add(flipInterval);
    }
  }

  /// Records a manual flip and calculates the next flip time
  static Future<DateTime> recordFlip(String batchId) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastFlipKey + batchId, now.millisecondsSinceEpoch);
    return now.add(flipInterval);
  }

  /// Clears the flip schedule for a batch
  static Future<void> clearFlipSchedule(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFlipKey + batchId);
  }

  /// Schedules egg flipping notifications for a batch
  static Future<void> scheduleEggFlipping({
    required String batchId,
    required String batchName,
  }) async {
    final nextFlipTime = await getNextFlipTime(batchId);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'egg_flip_channel',
        title: 'Retournement des œufs',
        body: 'Il est temps de retourner les œufs de la couvée $batchName',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: nextFlipTime,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  /// Cancels egg flipping notifications for a batch
  static Future<void> cancelEggFlipping(String batchId) async {
    await AwesomeNotifications().cancelAllSchedules();
    await clearFlipSchedule(batchId);
  }
}
