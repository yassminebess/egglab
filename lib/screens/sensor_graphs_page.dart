import 'package:flutter/material.dart';
import '../services/sensor_data_service.dart';
import '../widgets/sensor_graph.dart';

class SensorGraphsPage extends StatefulWidget {
  final SensorDataService sensorService;
  final String batchId;
  final String batchName;
  final DateTime startDate;

  const SensorGraphsPage({
    super.key,
    required this.sensorService,
    required this.batchId,
    required this.batchName,
    required this.startDate,
  });

  @override
  State<SensorGraphsPage> createState() => _SensorGraphsPageState();
}

class _SensorGraphsPageState extends State<SensorGraphsPage> {
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    widget.sensorService.startMonitoring(
      widget.batchId,
      widget.batchName,
      startDate: widget.startDate,
    );
  }

  @override
  void dispose() {
    widget.sensorService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphiques en Temps Réel'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<SensorDataPoint>>(
              stream: widget.sensorService.temperatureStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SensorGraph(
                  dataPoints: snapshot.data!,
                  title: 'Température',
                  unit: '°C',
                  minThreshold: SensorDataService.minTemp,
                  maxThreshold: SensorDataService.maxTemp,
                  normalColor: Colors.orange,
                  alertColor: Colors.red,
                );
              },
            ),
            const Divider(height: 32),
            StreamBuilder<List<SensorDataPoint>>(
              stream: widget.sensorService.humidityStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SensorGraph(
                  dataPoints: snapshot.data!,
                  title: 'Humidité',
                  unit: '%',
                  minThreshold: SensorDataService.minHumidity,
                  maxThreshold: SensorDataService.maxHumidity,
                  normalColor: Colors.blue,
                  alertColor: Colors.red,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isMonitoring) {
              widget.sensorService.stopMonitoring();
            } else {
              widget.sensorService.startMonitoring(
                widget.batchId,
                widget.batchName,
                startDate: widget.startDate,
              );
            }
            _isMonitoring = !_isMonitoring;
          });
        },
        tooltip: _isMonitoring
            ? 'Arrêter la surveillance'
            : 'Démarrer la surveillance',
        child: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
