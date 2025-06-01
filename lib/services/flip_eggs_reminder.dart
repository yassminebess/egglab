// lib/services/flip_eggs_reminder.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlipEggsReminder {
  static const String channelKey = "egg_flipping_channel";
  static const String reminderChannelKey = "egg_flipping_reminder_channel";
  static const String nextFlipTimeKey = "next_flip_time";
  static const Duration flipInterval = Duration(hours: 8);

  /// Initializes the egg flipping reminder channels
  static Future<void> initialize() async {
    // Main channel for the egg flipping notification
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: channelKey,
        channelName: 'Egg Flipping Reminders',
        channelDescription: 'Notifications to remind when to flip the eggs',
        defaultColor: Colors.amber,
        ledColor: Colors.yellow,
        importance: NotificationImportance.High,
        enableVibration: true,
        playSound: true,
        criticalAlerts: true,
        channelShowBadge: true,
      ),
    );

    // Channel for the 5 and 10 minute reminders
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: reminderChannelKey,
        channelName: 'Egg Flipping Advance Reminders',
        channelDescription: 'Reminders 5 and 10 minutes before flipping eggs',
        defaultColor: Colors.orange,
        ledColor: Colors.orangeAccent,
        importance: NotificationImportance.High,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
      ),
    );
  }

  /// Gets the stored next flip time for a batch
  static Future<DateTime> getNextFlipTime(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${nextFlipTimeKey}_$batchId';
    final storedTime = prefs.getInt(key);

    if (storedTime != null) {
      return DateTime.fromMillisecondsSinceEpoch(storedTime);
    } else {
      // No stored time, calculate a new one and store it
      final nextTime = _calculateNextFlipTime();
      await _storeNextFlipTime(batchId, nextTime);
      return nextTime;
    }
  }

  /// Calculates the next flip time based on the current time
  static DateTime _calculateNextFlipTime() {
    final now = DateTime.now();

    // Find the next scheduled hour for flipping (6:00, 14:00, 22:00)
    List<int> scheduledHours = [6, 14, 22];
    int nextHourIndex = scheduledHours.indexWhere((hour) => hour > now.hour);

    // If we're past the last scheduled hour, use the first one for tomorrow
    if (nextHourIndex == -1) nextHourIndex = 0;

    int nextHour = scheduledHours[nextHourIndex];

    // Create next scheduled time
    return DateTime(
        now.year,
        now.month,
        nextHourIndex == 0 && nextHour < now.hour ? now.day + 1 : now.day,
        nextHour,
        0,
        0);
  }

  /// Stores the next flip time for a batch
  static Future<void> _storeNextFlipTime(
      String batchId, DateTime nextTime) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${nextFlipTimeKey}_$batchId';
    await prefs.setInt(key, nextTime.millisecondsSinceEpoch);
  }

  /// Resets the flip schedule for a batch and creates new notifications
  static Future<void> resetFlipSchedule({
    required String batchId,
    required String batchName,
  }) async {
    // Calculate the next flip time (8 hours from now)
    final now = DateTime.now();
    final nextFlipTime = now.add(flipInterval);

    // Store the next flip time
    await _storeNextFlipTime(batchId, nextFlipTime);

    // Cancel existing notifications
    await cancelEggFlipping(batchId);

    // Schedule new flip notifications
    await _scheduleFlipNotification(
      batchId: batchId,
      batchName: batchName,
      scheduledTime: nextFlipTime,
    );

    // Schedule reminder notifications
    await _scheduleReminderNotifications(
      batchId: batchId,
      batchName: batchName,
      flipTime: nextFlipTime,
    );
  }

  /// Schedules the egg flipping reminder to repeat every 8 hours
  static Future<void> scheduleEggFlipping({
    required String batchId,
    required String batchName,
  }) async {
    // Cancel any existing reminders for this batch first
    await cancelEggFlipping(batchId);

    // Calculate next flip time
    final nextFlipTime = _calculateNextFlipTime();

    // Store the next flip time
    await _storeNextFlipTime(batchId, nextFlipTime);

    // Schedule the main flip notification
    await _scheduleFlipNotification(
        batchId: batchId, batchName: batchName, scheduledTime: nextFlipTime);

    // Schedule the reminder notifications
    await _scheduleReminderNotifications(
      batchId: batchId,
      batchName: batchName,
      flipTime: nextFlipTime,
    );
  }

  /// Schedules the main egg flipping notification
  static Future<void> _scheduleFlipNotification({
    required String batchId,
    required String batchName,
    required DateTime scheduledTime,
  }) async {
    // Create a deterministic notification ID from the batch ID
    final int notificationId = batchId.hashCode.abs().remainder(2147483647);

    // Get device timezone
    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    // Create the notification content
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: 'Retournement des oeufs',
        body: 'Il est temps de retourner les oeufs de la couvée: $batchName',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        criticalAlert: true,
        payload: {'batchId': batchId, 'batchName': batchName, 'action': 'flip'},
      ),
      schedule: NotificationCalendar(
        year: scheduledTime.year,
        month: scheduledTime.month,
        day: scheduledTime.day,
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: 0,
        repeats: false,
        preciseAlarm: true,
        allowWhileIdle: true,
        timeZone: localTimeZone,
      ),
    );
  }

  /// Schedules reminder notifications 5 and 10 minutes before the flip
  static Future<void> _scheduleReminderNotifications({
    required String batchId,
    required String batchName,
    required DateTime flipTime,
  }) async {
    // Create deterministic notification IDs
    final int baseId = batchId.hashCode.abs().remainder(2147483647);
    final int tenMinNotificationId = baseId + 1;
    final int fiveMinNotificationId = baseId + 2;

    // Get device timezone
    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    // Calculate reminder times
    final tenMinutesBefore = flipTime.subtract(const Duration(minutes: 10));
    final fiveMinutesBefore = flipTime.subtract(const Duration(minutes: 5));

    // Only schedule if the reminder time is in the future
    final now = DateTime.now();

    // 10-minute reminder
    if (tenMinutesBefore.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: tenMinNotificationId,
          channelKey: reminderChannelKey,
          title: 'Rappel: Retournement des oeufs dans 10 minutes',
          body: 'Préparez-vous à retourner les oeufs de la couvée: $batchName',
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          payload: {
            'batchId': batchId,
            'batchName': batchName,
            'action': 'reminder'
          },
        ),
        schedule: NotificationCalendar(
          year: tenMinutesBefore.year,
          month: tenMinutesBefore.month,
          day: tenMinutesBefore.day,
          hour: tenMinutesBefore.hour,
          minute: tenMinutesBefore.minute,
          second: 0,
          repeats: false,
          allowWhileIdle: true,
          timeZone: localTimeZone,
        ),
      );
    }

    // 5-minute reminder
    if (fiveMinutesBefore.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: fiveMinNotificationId,
          channelKey: reminderChannelKey,
          title: 'Rappel: Retournement des oeufs dans 5 minutes',
          body:
              'Veuillez retourner les oeufs de la couvée: $batchName très bientôt',
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          payload: {
            'batchId': batchId,
            'batchName': batchName,
            'action': 'reminder'
          },
        ),
        schedule: NotificationCalendar(
          year: fiveMinutesBefore.year,
          month: fiveMinutesBefore.month,
          day: fiveMinutesBefore.day,
          hour: fiveMinutesBefore.hour,
          minute: fiveMinutesBefore.minute,
          second: 0,
          repeats: false,
          allowWhileIdle: true,
          timeZone: localTimeZone,
        ),
      );
    }
  }

  /// Cancels the egg flipping reminders for a specific batch
  static Future<void> cancelEggFlipping(String batchId) async {
    final int baseId = batchId.hashCode.abs().remainder(2147483647);
    await AwesomeNotifications().cancel(baseId); // Main notification
    await AwesomeNotifications().cancel(baseId + 1); // 10-min reminder
    await AwesomeNotifications().cancel(baseId + 2); // 5-min reminder
  }

  /// Cancels all egg flipping reminders
  static Future<void> cancelAllEggFlipping() async {
    await AwesomeNotifications().cancelNotificationsByChannelKey(channelKey);
    await AwesomeNotifications()
        .cancelNotificationsByChannelKey(reminderChannelKey);
  }
}
