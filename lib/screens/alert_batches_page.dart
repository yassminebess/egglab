import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import 'alert_notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertBatchesPage extends StatefulWidget {
  final AlertService alertService;
  final BatchService batchService;

  const AlertBatchesPage({
    super.key,
    required this.alertService,
    required this.batchService,
  });

  @override
  State<AlertBatchesPage> createState() => _AlertBatchesPageState();
}

class _AlertBatchesPageState extends State<AlertBatchesPage> {
  List<Batch> _batches = [];
  bool _isLoading = true;
  Map<String, int> _alertCountsByBatch = {};

  @override
  void initState() {
    super.initState();
    _loadBatchesAndAlerts();
  }

  Future<void> _loadBatchesAndAlerts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load all batches
      final batches = await widget.batchService.getBatches();

      // Load active alerts
      final alerts = await widget.alertService.getAlerts(activeOnly: true);

      // Count alerts by batchId
      final Map<String, int> alertCountsByBatch = {};
      for (final alert in alerts) {
        if (alert.batchId != null) {
          alertCountsByBatch[alert.batchId!] =
              (alertCountsByBatch[alert.batchId!] ?? 0) + 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _batches = batches;
        _alertCountsByBatch = alertCountsByBatch;
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
        title: const Text('Alertes par Couvée'),
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
        final alertCount = _alertCountsByBatch[batch.id] ?? 0;
        return _buildBatchCard(batch, alertCount);
      },
    );
  }

  Widget _buildBatchCard(Batch batch, int alertCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlertNotificationsPage(
                batchId: batch.id,
                batchName: batch.name,
                alertService: widget.alertService,
              ),
            ),
          );
          // Refresh only if the widget is still mounted
          if (mounted) {
            _loadBatchesAndAlerts();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
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
                    batch.name,
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
            if (alertCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    alertCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
