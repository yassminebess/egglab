import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/flip_eggs_reminder.dart';

class EggFlipCountdown extends StatefulWidget {
  final String batchId;
  final String batchName;
  final Function()? onFlip;

  const EggFlipCountdown(
      {super.key, required this.batchId, required this.batchName, this.onFlip});

  @override
  State<EggFlipCountdown> createState() => _EggFlipCountdownState();
}

class _EggFlipCountdownState extends State<EggFlipCountdown> {
  late Timer _timer;
  DateTime _nextFlipTime = DateTime.now().add(const Duration(hours: 8));
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _loadNextFlipTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadNextFlipTime() async {
    // Get the next flip time from the service
    _nextFlipTime = await FlipEggsReminder.getNextFlipTime(widget.batchId);
    if (mounted) {
      _updateCountdown();
    }
  }

  void _startTimer() {
    // Update the countdown every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    if (now.isAfter(_nextFlipTime)) {
      // If we've passed the next flip time, update it
      _loadNextFlipTime();
      return;
    }

    final remaining = _nextFlipTime.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    setState(() {
      if (hours > 0) {
        _timeRemaining = '$hours h ${minutes.toString().padLeft(2, '0')} min';
      } else {
        _timeRemaining = '$minutes min';
      }
    });
  }

  Future<void> _manualFlip() async {
    if (widget.onFlip != null) {
      widget.onFlip!();
    }

    // Reset the schedule when the user flips the eggs manually
    await FlipEggsReminder.resetFlipSchedule(
      batchId: widget.batchId,
      batchName: widget.batchName,
    );

    // Update the next flip time
    await _loadNextFlipTime();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.rotate_right, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prochain retournement des oeufs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dans $_timeRemaining',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
            ),
            Text(
              'Prévu à ${DateFormat('HH:mm').format(_nextFlipTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _manualFlip,
              icon: const Icon(Icons.touch_app),
              label: const Text('J\'ai retourné les oeufs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
