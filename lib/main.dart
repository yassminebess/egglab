import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/alert_service.dart';
import 'services/batch_service.dart';
import 'services/component_service.dart';
import 'services/history_service.dart';
import 'services/sensor_data_service.dart';
import 'screens/home_page.dart';
import 'services/flip_eggs_reminder.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // Use default app icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.yellow,
        importance: NotificationImportance.High,
        enableVibration: true,
      ),
    ],
  );

  // Initialize egg flipping reminder channel
  await FlipEggsReminder.initialize();

  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  // Set up notification listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final notificationService = NotificationService();
  await notificationService.initialize();

  final alertService = AlertService(prefs, notificationService);
  final historyService = HistoryService(prefs);
  final batchService = BatchService(
    prefs,
    alertService,
    historyService,
  );
  final sensorService =
      SensorDataService(alertService, batchService, historyService);
  final componentService = ComponentService(prefs, alertService);

  // Start periodic checks
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    try {
      await componentService.checkComponentLifespans();
      await batchService.checkBatchStatus();
    } catch (e) {
      debugPrint('Error in periodic checks: $e');
    }
  });

  runApp(
    MyApp(
      alertService: alertService,
      batchService: batchService,
      componentService: componentService,
      historyService: historyService,
      sensorService: sensorService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AlertService alertService;
  final BatchService batchService;
  final ComponentService componentService;
  final HistoryService historyService;
  final SensorDataService sensorService;

  const MyApp({
    super.key,
    required this.alertService,
    required this.batchService,
    required this.componentService,
    required this.historyService,
    required this.sensorService,
  });

  // Global navigator key for navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EggLab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8C6D00)),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: HomePage(
        alertService: alertService,
        batchService: batchService,
        componentService: componentService,
        historyService: historyService,
        sensorService: sensorService,
      ),
    );
  }
}

/// Notification controller to handle notification events
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.title}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.title}');

    // You can navigate to a specific page based on the notification
    if (receivedAction.payload != null) {
      // Handle egg flipping notifications
      if (receivedAction.payload!.containsKey('action') &&
          receivedAction.payload!['action'] == 'flip') {
        final String batchId = receivedAction.payload!['batchId'] ?? '';
        final String batchName =
            receivedAction.payload!['batchName'] ?? 'Couvée';

        // Reset the flip schedule when user interacts with the notification
        await FlipEggsReminder.resetFlipSchedule(
          batchId: batchId,
          batchName: batchName,
        );

        // Navigate to the batch details page
        MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text('Détails de $batchName'),
              ),
              body: const Center(
                child: Text('Les oeufs ont été retournés.'),
              ),
            ),
          ),
        );
      }
      // Handle regular batch notifications
      else if (receivedAction.payload!.containsKey('batchId')) {
        final String batchId = receivedAction.payload!['batchId'] ?? '';
        final String batchName =
            receivedAction.payload!['batchName'] ?? 'Couvée';

        // Use the navigator key to navigate to the batch details page
        MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text('Détails de $batchName'),
              ),
              body: Center(
                child: Text('Détails du batch $batchId'),
              ),
            ),
          ),
        );
      }
    }
  }
}
