import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/batch_service.dart';
import '../services/component_service.dart';
import '../services/history_service.dart';
import '../services/sensor_data_service.dart';
import '../services/incubation_report_service.dart';
import 'history_batches_page.dart';
import 'alert_batches_page.dart';
import 'batch_page.dart';
import 'components_page.dart';

class HomePage extends StatefulWidget {
  final AlertService alertService;
  final BatchService batchService;
  final ComponentService componentService;
  final HistoryService historyService;
  final SensorDataService sensorService;
  final IncubationReportService reportService;

  const HomePage({
    super.key,
    required this.alertService,
    required this.batchService,
    required this.componentService,
    required this.historyService,
    required this.sensorService,
    required this.reportService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 40, height: 40),
            const SizedBox(width: 10),
            const Text('EggLab'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
              Theme.of(context).colorScheme.primaryContainer.withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _MenuItem(
                      icon: Icons.egg_outlined,
                      label: 'Ma Couvée',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BatchPage(
                            batchService: widget.batchService,
                            alertService: widget.alertService,
                            historyService: widget.historyService,
                            sensorService: widget.sensorService,
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.history,
                      label: 'Historique',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryBatchesPage(
                            historyService: widget.historyService,
                            batchService: widget.batchService,
                            reportService: widget.reportService,
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Alertes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlertBatchesPage(
                            alertService: widget.alertService,
                            batchService: widget.batchService,
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.build_outlined,
                      label: 'Durée de Vie des Composants',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComponentsPage(
                            componentService: widget.componentService,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/chick_2.gif',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
