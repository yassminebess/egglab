import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert.dart';

class AlertsPage extends StatefulWidget {
  final AlertService alertService;

  const AlertsPage({super.key, required this.alertService});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Alert> _alerts = [];
  bool _showResolvedAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await widget.alertService.getAlerts();
    setState(() {
      _alerts = alerts;
    });
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.humidity:
        return Icons.water_drop;
      case AlertType.eggFlipping:
        return Icons.rotate_right;
      case AlertType.componentLifespan:
        return Icons.build;
      case AlertType.sensorFailure:
        return Icons.error_outline;
      case AlertType.fanMalfunction:
        return Icons.wind_power;
      case AlertType.lampMalfunction:
        return Icons.lightbulb_outline;
      case AlertType.manualOverride:
        return Icons.pan_tool;
    }
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.temperature:
      case AlertType.humidity:
      case AlertType.sensorFailure:
      case AlertType.fanMalfunction:
      case AlertType.lampMalfunction:
        return Colors.red;
      case AlertType.componentLifespan:
        return Colors.orange;
      case AlertType.eggFlipping:
      case AlertType.manualOverride:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alerts.where((alert) => !alert.isResolved).toList();
    final resolvedAlerts = _alerts.where((alert) => alert.isResolved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          IconButton(
            icon: Icon(
              _showResolvedAlerts ? Icons.history_toggle_off : Icons.history,
            ),
            onPressed: () {
              setState(() {
                _showResolvedAlerts = !_showResolvedAlerts;
              });
            },
            tooltip: _showResolvedAlerts ? 'Masquer résolues' : 'Voir résolues',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount:
            _showResolvedAlerts ? resolvedAlerts.length : activeAlerts.length,
        itemBuilder: (context, index) {
          final alert =
              _showResolvedAlerts ? resolvedAlerts[index] : activeAlerts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                _getAlertIcon(alert.type),
                color: _getAlertColor(alert.type),
              ),
              title: Text(alert.message),
              subtitle: Text(
                'Couvée: ${alert.batchId ?? "N/A"}\n'
                '${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year} '
                '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
              ),
              trailing: !alert.isResolved
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () async {
                        await widget.alertService.resolveAlert(alert.id);
                        await _loadAlerts();
                      },
                      tooltip: 'Marquer comme résolu',
                    )
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
