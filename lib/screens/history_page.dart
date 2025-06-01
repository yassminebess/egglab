// lib/screens/history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_event.dart';
import '../services/history_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatefulWidget {
  final HistoryService historyService;

  const HistoryPage({
    super.key,
    required this.historyService,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _selectedBatchId;
  String? _selectedBatchName;
  List<HistoryEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final events = await widget.historyService.getHistoryEvents(
      batchId: _selectedBatchId,
    );

    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  Widget _buildEventIcon(HistoryEvent event) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        event.icon,
        color: event.getStatusColor(context),
      ),
    );
  }

  Widget _buildEventTile(HistoryEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildEventIcon(event),
        title: Text(
          event.description,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Only show batch name if all batches are being shown
            if (_selectedBatchId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Couvée: ${event.batchName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(event.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: event.status == EventStatus.success
            ? const Icon(Icons.check_circle, color: Colors.green)
            : event.status == EventStatus.warning
                ? const Icon(Icons.warning_amber, color: Colors.amber)
                : event.status == EventStatus.critical
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
      ),
    );
  }

  void _showBatchSelectionDialog() async {
    final batches = await widget.historyService.getBatchNamesEntries();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par couvée'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Toutes les couvées'),
                selected: _selectedBatchId == null,
                leading: const Icon(Icons.list),
                onTap: () {
                  setState(() {
                    _selectedBatchId = null;
                    _selectedBatchName = null;
                  });
                  _loadEvents();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...batches.map((entry) => ListTile(
                    title: Text(entry.value),
                    subtitle: Text('ID: ${entry.key}'),
                    selected: _selectedBatchId == entry.key,
                    leading: const Icon(Icons.egg_outlined),
                    onTap: () {
                      setState(() {
                        _selectedBatchId = entry.key;
                        _selectedBatchName = entry.value;
                      });
                      _loadEvents();
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBatchName != null
            ? 'Couvée: $_selectedBatchName'
            : 'Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showBatchSelectionDialog,
            tooltip: 'Filtrer par couvée',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun événement à afficher',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_selectedBatchId != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.filter_list_off),
                          label: const Text('Afficher toutes les couvées'),
                          onPressed: () {
                            setState(() {
                              _selectedBatchId = null;
                              _selectedBatchName = null;
                            });
                            _loadEvents();
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventTile(event);
                  },
                ),
    );
  }
}
