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
      debugPrint('Loaded batches: ${batches.length}');
      for (final batch in batches) {
        debugPrint(
            'Batch: ${batch.name} (ID: ${batch.id}, Active: ${batch.isActive})');
      }
      if (mounted) {
        setState(() {
          _batches = batches;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading batches: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des couvées: $e';
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Réinitialiser les données'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir réinitialiser toutes les données des couvées ? Cette action est irréversible.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await widget.batchService.resetBatches();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Données réinitialisées avec succès'),
                        ),
                      );
                      _loadBatches();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Erreur lors de la réinitialisation: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } else if (value == 'add_test') {
                try {
                  await widget.batchService.addTestBatch();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Couvée test ajoutée avec succès'),
                      ),
                    );
                    _loadBatches();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Erreur lors de l\'ajout de la couvée test: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Réinitialiser les données'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_test',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Ajouter une couvée test'),
                  ],
                ),
              ),
            ],
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Démarré le: ${_formatDate(batch.startDate)}'),
                                  Text('Nombre d\'œufs: ${batch.numberOfEggs}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.show_chart),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SensorGraphsPage(
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
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              const Text('Supprimer la couvée'),
                                          content: Text(
                                            'Êtes-vous sûr de vouloir supprimer la couvée "${batch.name}" ? Cette action est irréversible.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Annuler'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Supprimer'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          await widget.batchService
                                              .deleteBatch(batch.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Couvée supprimée avec succès'),
                                              ),
                                            );
                                            _loadBatches();
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Erreur lors de la suppression: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    tooltip: 'Supprimer la couvée',
                                  ),
                                ],
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
    bool isDialogClosed = false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
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
                if (!isDialogClosed) {
                  isDialogClosed = true;
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    eggsController.text.isEmpty) {
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
                  if (mounted && !isDialogClosed) {
                    isDialogClosed = true;
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
    } finally {
      nameController.dispose();
      eggsController.dispose();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
