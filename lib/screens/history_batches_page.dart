import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'history_notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/batch_service.dart';
import '../services/incubation_report_service.dart';
import 'batch_reports_page.dart';

class HistoryBatchesPage extends StatefulWidget {
  final HistoryService historyService;
  final BatchService batchService;
  final IncubationReportService reportService;

  const HistoryBatchesPage({
    super.key,
    required this.historyService,
    required this.batchService,
    required this.reportService,
  });

  @override
  State<HistoryBatchesPage> createState() => _HistoryBatchesPageState();
}

class _HistoryBatchesPageState extends State<HistoryBatchesPage> {
  List<MapEntry<String, String>> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final historyBatches = await widget.historyService.getBatchNamesEntries();
      final batchList = await widget.batchService.getBatches();
      final batchIds = batchList.map((b) => b.id).toSet();
      final filtered = historyBatches
          .where((entry) => batchIds.contains(entry.key))
          .toList();
      if (!mounted) return;
      setState(() {
        _batches = filtered;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withAlpha(77),
              colorScheme.primaryContainer.withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _batches.isEmpty
                ? _buildEmptyState()
                : _buildBatchesGrid(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.egg_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune couvée à afficher',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final batch = _batches[index];
        return _buildBatchCard(batch);
      },
    );
  }

  Widget _buildBatchCard(MapEntry<String, String> batch) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchReportsPage(
                    batchId: batch.key,
                    batchName: batch.value,
                    reportService: widget.reportService,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.egg_alt,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    batch.value,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer la couvée'),
                      content: Text(
                        'Êtes-vous sûr de vouloir supprimer la couvée "${batch.value}" et tout son historique ? Cette action est irréversible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await widget.batchService.deleteBatch(batch.key);
                      await widget.reportService
                          .deleteReportsForBatch(batch.key);
                      await widget.historyService
                          .clearHistory(batchId: batch.key);
                      if (mounted) {
                        setState(() {
                          _batches.remove(batch);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Couvée supprimée avec succès'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la suppression: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
