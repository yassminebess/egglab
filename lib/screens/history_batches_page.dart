import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'history_notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryBatchesPage extends StatefulWidget {
  final HistoryService historyService;

  const HistoryBatchesPage({
    super.key,
    required this.historyService,
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
      final batches = await widget.historyService.getBatchNamesEntries();
      if (!mounted) return;
      setState(() {
        _batches = batches;
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryNotificationsPage(
                batchId: batch.key,
                batchName: batch.value,
                historyService: widget.historyService,
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
    );
  }
}
