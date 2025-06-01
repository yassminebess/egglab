// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egglab/main.dart';
import 'package:egglab/services/alert_service.dart';
import 'package:egglab/services/batch_service.dart';
import 'package:egglab/services/component_service.dart';
import 'package:egglab/services/notification_service.dart';
import 'package:egglab/services/history_service.dart';
import 'package:egglab/services/sensor_data_service.dart';

void main() {
  testWidgets('EggLab app smoke test', (WidgetTester tester) async {
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Initialize services
    final notificationService = NotificationService();
    await notificationService.initialize();

    final historyService = HistoryService(prefs);
    final alertService = AlertService(prefs, notificationService);
    final batchService = BatchService(
      prefs,
      alertService,
      historyService,
    );
    final sensorService =
        SensorDataService(alertService, batchService, historyService);
    final componentService = ComponentService(prefs, alertService);

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MyApp(
        alertService: alertService,
        batchService: batchService,
        componentService: componentService,
        historyService: historyService,
        sensorService: sensorService,
      ),
    );

    // Verify that our app starts with the home page
    expect(find.text('EggLab'), findsOneWidget);

    // Verify that main menu items are present
    expect(find.text('Ma Couvée'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Alertes'), findsOneWidget);
    expect(find.text('Durée de Vie des Composants'), findsOneWidget);

    // Verify that we can navigate to the batch page
    await tester.tap(find.text('Ma Couvée'));
    await tester.pumpAndSettle();
    expect(find.text('Couvées'), findsOneWidget);
    expect(find.text('Aucune couvée en cours'), findsOneWidget);

    // Clean up
    await notificationService.cancelAllNotifications();
    await prefs.clear();
  });
}
