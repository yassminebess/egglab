import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';
import '../services/alert_service.dart';
import '../services/sensor_data_service.dart';
import '../services/history_service.dart';
import 'hatch_detail_page.dart';
import 'sensor_graphs_page.dart';

class BatchPage extends StatefulWidget {
  final BatchService batchService;
  final AlertService alertService;
  final HistoryService historyService;
  final SensorDataService sensorService;

  const BatchPage({
    super.key,
    required this.batchService,
    required this.alertService,
    required this.historyService,
    required this.sensorService,
  });

  @override
  State<BatchPage> createState() => _BatchPageState();
}

class _BatchPageState extends State<BatchPage> {
  bool _isLoading = true;
  List<Batch> _batches = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final batches = await widget.batchService.getBatches();
      if (mounted) {
        setState(() {
          _batches = batches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des couvées';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadBatches,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couvées'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatches,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBatches,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _batches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Aucune couvée en cours'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showAddBatchDialog(context),
                            child: const Text('Ajouter une couvée'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBatches,
                      child: ListView.builder(
                        itemCount: _batches.length,
                        itemBuilder: (context, index) {
                          final batch = _batches[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(batch.name),
                              subtitle: Text(
                                  'Démarré le: ${_formatDate(batch.startDate)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.show_chart),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SensorGraphsPage(
                                        sensorService: widget.sensorService,
                                        batchId: batch.id,
                                        batchName: batch.name,
                                        startDate: batch.startDate,
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'Voir les graphiques',
                              ),
                              onTap: () async {
                                try {
                                  // Stop any existing monitoring before navigating
                                  widget.sensorService.stopMonitoring();

                                  if (!mounted) return;

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HatchDetailPage(
                                        batch: batch,
                                        batchService: widget.batchService,
                                        alertService: widget.alertService,
                                        historyService: widget.historyService,
                                        sensorService: widget.sensorService,
                                      ),
                                    ),
                                  );

                                  // Reload batches after returning from detail page
                                  if (mounted) {
                                    await _loadBatches();
                                  }
                                } catch (e) {
                                  debugPrint(
                                      'Error navigating to HatchDetailPage: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchDialog(context),
        tooltip: 'Ajouter une couvée',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddBatchDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final eggsController = TextEditingController();
    DateTime startDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Couvée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la couvée',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: eggsController,
              decoration: const InputDecoration(
                labelText: 'Nombre d\'oeufs',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || eggsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }

              final eggCount = int.tryParse(eggsController.text) ?? 0;
              if (eggCount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Le nombre d\'oeufs doit être supérieur à 0')),
                );
                return;
              }

              try {
                await widget.batchService.addBatch(
                  name: nameController.text,
                  eggCount: eggCount,
                  startDate: startDate,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  await _loadBatches();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    nameController.dispose();
    eggsController.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
