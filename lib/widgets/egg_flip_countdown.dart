import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EggFlipCountdown extends StatefulWidget {
  final String batchId;
  final String batchName;

  const EggFlipCountdown({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<EggFlipCountdown> createState() => _EggFlipCountdownState();
}

class _EggFlipCountdownState extends State<EggFlipCountdown> {
  DateTime? _nextFlipTime;
  bool _isLoading = true;
  Timer? _timer;
  SharedPreferences? _prefs;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    if (!mounted) return;

    try {
      _isError = false;
      _prefs = await SharedPreferences.getInstance();
      final lastFlipTime = _prefs?.getInt('last_flip_time_${widget.batchId}');

      if (lastFlipTime != null) {
        _nextFlipTime = DateTime.fromMillisecondsSinceEpoch(lastFlipTime)
            .add(const Duration(hours: 8));
      } else {
        // If no last flip time, set it to now and save it
        final now = DateTime.now();
        _nextFlipTime = now.add(const Duration(hours: 8));
        await _prefs?.setInt(
            'last_flip_time_${widget.batchId}', now.millisecondsSinceEpoch);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
      _isError = false;
      final now = DateTime.now();
      _prefs ??= await SharedPreferences.getInstance();

      await _prefs?.setInt(
          'last_flip_time_${widget.batchId}', now.millisecondsSinceEpoch);

      if (!mounted) return;
      setState(() {
        _nextFlipTime = now.add(const Duration(hours: 8));
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flip enregistré avec succès'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement du flip'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getTimeRemaining() {
    if (_nextFlipTime == null) return '--:--';
    final now = DateTime.now();
    final difference = _nextFlipTime!.difference(now);

    if (difference.isNegative) {
      final hoursOverdue = difference.inHours.abs();
      final minutesOverdue = difference.inMinutes.remainder(60).abs();
      return 'En retard de $hoursOverdue:${minutesOverdue.toString().padLeft(2, '0')}';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor() {
    if (_isError) return Colors.grey;
    if (_nextFlipTime == null) return Colors.grey;

    final now = DateTime.now();
    final difference = _nextFlipTime!.difference(now);

    if (difference.isNegative) {
      return Colors.amber.shade700;
    } else if (difference.inHours < 1) {
      return Colors.amber;
    }
    return Colors.amber.shade400;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prefs = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeTimer,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
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

    final isOverdue =
        _nextFlipTime != null && _nextFlipTime!.isBefore(DateTime.now());
    final timeColor = _getTimeColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              timeColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOverdue ? Icons.warning_amber_rounded : Icons.timer,
                    color: timeColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOverdue
                        ? 'Retournement en retard'
                        : 'Prochain retournement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _getTimeRemaining(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _recordFlip,
                icon: const Icon(Icons.flip_camera_android),
                label: const Text('Enregistrer le retournement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: timeColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
