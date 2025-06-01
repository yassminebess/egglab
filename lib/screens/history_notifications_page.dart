import 'package:flutter/material.dart';
import '../models/history_event.dart';
import '../services/history_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryNotificationsPage extends StatefulWidget {
  final String batchId;
  final String batchName;
  final HistoryService historyService;

  const HistoryNotificationsPage({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.historyService,
  });

  @override
  State<HistoryNotificationsPage> createState() =>
      _HistoryNotificationsPageState();
}

class _HistoryNotificationsPageState extends State<HistoryNotificationsPage> {
  List<HistoryEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final events = await widget.historyService.getHistoryEvents(
        batchId: widget.batchId,
      );

      if (!mounted) return;
      setState(() {
        _events = events;
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
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(event.timestamp),
          style: Theme.of(context).textTheme.bodySmall,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Couvée: ${widget.batchName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventTile(event);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification pour cette couvée',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
