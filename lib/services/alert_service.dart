import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert.dart';
import 'notification_service.dart';
import '../services/flip_eggs_reminder.dart';

class AlertService {
  static const String _alertsKey = 'alerts';
  final SharedPreferences _prefs;
  final NotificationService _notificationService;

  AlertService(this._prefs, this._notificationService);

  Future<List<Alert>> getAlerts({bool activeOnly = false}) async {
    final alertsJson = _prefs.getStringList(_alertsKey) ?? [];
    final alerts = alertsJson
        .map((json) => Alert.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (activeOnly) {
      return alerts.where((alert) => !alert.isResolved).toList();
    }
    return alerts;
  }

  Future<void> addAlert(
    AlertType type,
    String message,
    String? batchId,
  ) async {
    final alert = Alert(
      id: DateTime.now().toString(),
      type: type,
      message: message,
      timestamp: DateTime.now(),
      batchId: batchId,
    );

    final alerts = await getAlerts();
    alerts.add(alert);
    await _saveAlerts(alerts);

    // Send notification
    await _notifyAlert(alert);
  }

  Future<void> resolveAlert(String alertId) async {
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a.id == alertId);

    if (index != -1) {
      alerts[index] = alerts[index].copyWith(isResolved: true);
      await _saveAlerts(alerts);
    }
  }

  Future<void> _saveAlerts(List<Alert> alerts) async {
    await _prefs.setStringList(
      _alertsKey,
      alerts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<void> _notifyAlert(Alert alert) async {
    String title;
    String body = alert.message;
    bool isImportant = false;

    switch (alert.type) {
      case AlertType.temperature:
        title = '🌡️ Alerte Température';
        isImportant = true;
        break;
      case AlertType.humidity:
        title = '💧 Alerte Humidité';
        isImportant = true;
        break;
      case AlertType.eggFlipping:
        title = '🥚 Retournement des Oeufs';
        break;
      case AlertType.componentLifespan:
        title = '⚠️ Durée de Vie Composant';
        isImportant = true;
        break;
      case AlertType.sensorFailure:
        title = '❌ Défaillance Capteur';
        isImportant = true;
        break;
      case AlertType.fanMalfunction:
        title = '🌪️ Défaillance Ventilateur';
        isImportant = true;
        break;
      case AlertType.lampMalfunction:
        title = '💡 Défaillance Lampe';
        isImportant = true;
        break;
      case AlertType.manualOverride:
        title = '👋 Intervention Manuelle';
        break;
    }

    await _notificationService.showNotification(
      title: title,
      body: body,
      isImportant: isImportant,
    );
  }

  Future<void> scheduleEggFlipping(String batchId) async {
    // Find batch name from batchId
    final alerts = await getAlerts();
    final batchAlerts = alerts.where((a) => a.batchId == batchId).toList();
    String batchName = batchId; // Default value

    if (batchAlerts.isNotEmpty) {
      // Find the name from any alert related to this batch
      batchName = batchAlerts.first.message.contains('couvée: ')
          ? batchAlerts.first.message.split('couvée: ').last
          : batchId;
    }

    // First add an alert to the history
    await addAlert(
      AlertType.eggFlipping,
      'Il est temps de retourner les oeufs',
      batchId,
    );

    // Then schedule the egg flipping notifications using the new system
    await FlipEggsReminder.scheduleEggFlipping(
      batchId: batchId,
      batchName: batchName,
    );
  }

  Future<void> checkTemperature(double temperature, String batchId) async {
    const minTemp = 37.5;
    const maxTemp = 38.5;

    if (temperature < minTemp) {
      await addAlert(
        AlertType.temperature,
        'Température trop basse: ${temperature.toStringAsFixed(1)}°C',
        batchId,
      );
    } else if (temperature > maxTemp) {
      await addAlert(
        AlertType.temperature,
        'Température trop élevée: ${temperature.toStringAsFixed(1)}°C',
        batchId,
      );
    }
  }

  Future<void> checkHumidity(double humidity, String batchId) async {
    const minHumidity = 55.0;
    const maxHumidity = 65.0;

    if (humidity < minHumidity) {
      await addAlert(
        AlertType.humidity,
        'Humidité trop basse: ${humidity.toStringAsFixed(1)}%',
        batchId,
      );
    } else if (humidity > maxHumidity) {
      await addAlert(
        AlertType.humidity,
        'Humidité trop élevée: ${humidity.toStringAsFixed(1)}%',
        batchId,
      );
    }
  }
}
