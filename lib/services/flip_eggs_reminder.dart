// lib/services/flip_eggs_reminder.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';

class FlipEggsReminder {
  static const String _lastFlipKey = 'last_flip_time_';
  static const Duration flipInterval = Duration(hours: 8);
  static const int incubationPeriodDays = 21;

  /// Gets the next flip time for a batch
  static Future<DateTime?> getNextFlipTime(
      String batchId, BatchService batchService) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFlipTime = prefs.getInt(_lastFlipKey + batchId);

    // Get batch to check incubation period
    final batch = await batchService.getBatch(batchId);
    if (batch == null) return null;

    // Check if incubation period is complete
    final daysSinceStart = DateTime.now().difference(batch.startDate).inDays;
    if (daysSinceStart >= incubationPeriodDays) {
      await clearFlipSchedule(batchId);
      return null;
    }

    if (lastFlipTime != null) {
      final nextFlipTime =
          DateTime.fromMillisecondsSinceEpoch(lastFlipTime).add(flipInterval);
      // If more than 8 hours have passed since last flip, return null to indicate missed turn
      if (DateTime.now().isAfter(nextFlipTime)) {
        return null;
      }
      return nextFlipTime;
    } else {
      // If no last flip time is recorded, return 8 hours from now
      return DateTime.now().add(flipInterval);
    }
  }

  /// Records a manual flip and calculates the next flip time
  static Future<DateTime?> recordFlip(
      String batchId, BatchService batchService) async {
    final batch = await batchService.getBatch(batchId);
    if (batch == null) return null;

    // Check if incubation period is complete
    final daysSinceStart = DateTime.now().difference(batch.startDate).inDays;
    if (daysSinceStart >= incubationPeriodDays) {
      await clearFlipSchedule(batchId);
      return null;
    }

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
    required BatchService batchService,
  }) async {
    final nextFlipTime = await getNextFlipTime(batchId, batchService);
    if (nextFlipTime == null) {
      // Either incubation period is complete or turn was missed
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: '🥚 Retournement des Oeufs',
        body: 'Il est temps de retourner les oeufs de la couvée: $batchName',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: nextFlipTime),
    );
  }

  /// Cancels egg flipping notifications for a batch
  static Future<void> cancelEggFlipping(String batchId) async {
    await AwesomeNotifications().cancelAllSchedules();
    await clearFlipSchedule(batchId);
  }
}
