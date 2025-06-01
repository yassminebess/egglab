import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertNotificationsPage extends StatefulWidget {
  final String batchId;
  final String batchName;
  final AlertService alertService;

  const AlertNotificationsPage({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.alertService,
  });

  @override
  State<AlertNotificationsPage> createState() => _AlertNotificationsPageState();
}

class _AlertNotificationsPageState extends State<AlertNotificationsPage> {
  List<Alert> _alerts = [];
  bool _isLoading = true;
  bool _showResolvedAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final allAlerts = await widget.alertService.getAlerts();

      // Filter alerts for this batch only
      final batchAlerts =
          allAlerts.where((alert) => alert.batchId == widget.batchId).toList();

      if (!mounted) return;
      setState(() {
        _alerts = batchAlerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
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
    final displayAlerts = _showResolvedAlerts ? resolvedAlerts : activeAlerts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alertes: ${widget.batchName}'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayAlerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(displayAlerts),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showResolvedAlerts
                ? Icons.task_alt
                : Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showResolvedAlerts
                ? 'Aucune alerte résolue pour cette couvée'
                : 'Aucune alerte active pour cette couvée',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<Alert> alerts) {
    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              _getAlertIcon(alert.type),
              color: _getAlertColor(alert.type),
              size: 32,
            ),
            title: Text(
              alert.message,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(alert.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: !alert.isResolved
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () async {
                      await widget.alertService.resolveAlert(alert.id);
                      if (mounted) {
                        await _loadAlerts();
                      }
                    },
                    tooltip: 'Marquer comme résolu',
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
