import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static const String _channelKey = 'egglab_channel';
  static const String _importantChannelKey = 'egglab_important_channel';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: _channelKey,
            channelName: 'Basic Notifications',
            channelDescription: 'Basic notifications channel',
            defaultColor: const Color(0xFF8C6D00),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: _importantChannelKey,
            channelName: 'Important Notifications',
            channelDescription: 'Important notifications channel',
            defaultColor: const Color(0xFFFF0000),
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            criticalAlerts: true,
          ),
        ],
      );

      await requestPermission();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool isImportant = false,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: isImportant ? _importantChannelKey : _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? batchId,
  }) async {
    try {
      // Get local timezone for proper scheduling
      String localTimeZone =
          await AwesomeNotifications().getLocalTimeZoneIdentifier();

      // Create a unique hash code from the ID string
      final int idHash = id.hashCode.abs().remainder(2147483647);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: idHash,
          channelKey: _channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          payload: batchId != null ? {'batchId': batchId} : null,
        ),
        schedule: NotificationCalendar(
          year: scheduledDate.year,
          month: scheduledDate.month,
          day: scheduledDate.day,
          hour: scheduledDate.hour,
          minute: scheduledDate.minute,
          second: scheduledDate.second,
          timeZone: localTimeZone,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
      debugPrint(
          'Notification scheduled successfully for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(String id) async {
    try {
      await AwesomeNotifications().cancel(int.parse(id));
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> cancelBatchNotifications(String batchId) async {
    try {
      final List<NotificationModel> notifications =
          await AwesomeNotifications().listScheduledNotifications();

      for (var notification in notifications) {
        if (notification.content?.payload?['batchId'] == batchId) {
          await AwesomeNotifications().cancel(notification.content!.id!);
        }
      }
    } catch (e) {
      debugPrint('Error canceling batch notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  Future<void> scheduleEggFlipNotification(DateTime startDate) async {
    // Schedule notifications for egg flipping every 8 hours
    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    for (int i = 1; i <= 18; i++) {
      final scheduledDate = startDate.add(Duration(hours: i * 8));
      if (scheduledDate.isBefore(startDate.add(const Duration(days: 18)))) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: i,
            channelKey: _channelKey,
            title: 'Retournement des œufs',
            body: 'Il est temps de retourner les œufs !',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar(
            year: scheduledDate.year,
            month: scheduledDate.month,
            day: scheduledDate.day,
            hour: scheduledDate.hour,
            minute: scheduledDate.minute,
            second: scheduledDate.second,
            timeZone: localTimeZone,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  Future<void> scheduleHatchingReminder(DateTime startDate) async {
    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    final hatchDate = startDate.add(const Duration(days: 19));
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1000,
        channelKey: _importantChannelKey,
        title: 'Éclosion proche !',
        body: 'Plus que 2 jours avant l\'éclosion !',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: hatchDate.year,
        month: hatchDate.month,
        day: hatchDate.day,
        hour: hatchDate.hour,
        minute: hatchDate.minute,
        second: hatchDate.second,
        timeZone: localTimeZone,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> showComponentAlert(String componentName, int daysLeft) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _importantChannelKey,
        title: 'Alerte composant',
        body:
            'Le composant $componentName doit être remplacé dans $daysLeft jours',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFFFF0000),
      ),
    );
  }
}
