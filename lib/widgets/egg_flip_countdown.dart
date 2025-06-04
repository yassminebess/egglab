import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/batch_service.dart';
import '../services/flip_eggs_reminder.dart';
import '../services/alert_service.dart';

class EggFlipCountdown extends StatefulWidget {
  final String batchId;
  final String batchName;
  final BatchService batchService;
  final AlertService alertService;

  const EggFlipCountdown({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.batchService,
    required this.alertService,
  });

  @override
  State<EggFlipCountdown> createState() => _EggFlipCountdownState();
}

class _EggFlipCountdownState extends State<EggFlipCountdown> {
  DateTime? _nextFlipTime;
  bool _isLoading = true;
  Timer? _timer;
  bool _isError = false;
  bool _isMissedTurn = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    if (!mounted) return;

    try {
      _isError = false;
      _nextFlipTime = await FlipEggsReminder.getNextFlipTime(
        widget.batchId,
        widget.batchService,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isMissedTurn = _nextFlipTime == null;
      });

      // Start timer to update every minute
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  Future<void> _recordFlip() async {
    if (!mounted) return;

    try {
      final nextFlipTime = await FlipEggsReminder.recordFlip(
        widget.batchId,
        widget.batchService,
      );

      if (!mounted) return;
      setState(() {
        _nextFlipTime = nextFlipTime;
        _isMissedTurn = false;
      });

      // Schedule next notification
      await FlipEggsReminder.scheduleEggFlipping(
        batchId: widget.batchId,
        batchName: widget.batchName,
        batchService: widget.batchService,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement du retournement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return const Center(
        child: Text('Erreur lors du chargement du timer'),
      );
    }

    if (_nextFlipTime == null) {
      if (_isMissedTurn) {
        return Card(
          color: Colors.red.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  '⚠️ Retournement manqué',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _recordFlip,
                  child: const Text('Enregistrer le retournement'),
                ),
              ],
            ),
          ),
        );
      } else {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Période d\'incubation terminée',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }
    }

    final now = DateTime.now();
    final difference = _nextFlipTime!.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Prochain retournement dans:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$hours heures et $minutes minutes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _recordFlip,
              child: const Text('Enregistrer le retournement'),
            ),
          ],
        ),
      ),
    );
  }
}
