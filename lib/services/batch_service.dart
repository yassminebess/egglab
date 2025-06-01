import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch.dart';
import '../models/history_event.dart';
import '../services/alert_service.dart';
import '../services/history_service.dart';
import '../services/flip_eggs_reminder.dart';
import 'package:flutter/foundation.dart';

class BatchService {
  static const String _batchesKey = 'batches';
  final SharedPreferences _prefs;
  final AlertService _alertService;
  final HistoryService _historyService;
  final List<Batch> _batches = [];

  BatchService(
    this._prefs,
    this._alertService,
    this._historyService,
  ) {
    _loadBatchesFromPrefs();
  }

  Future<void> _loadBatchesFromPrefs() async {
    try {
      final batchStrings = _prefs.getStringList(_batchesKey) ?? [];
      _batches.clear();
      for (final batchString in batchStrings) {
        try {
          final json = jsonDecode(batchString);
          _batches.add(Batch.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing batch: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading batches from SharedPreferences: $e');
      _batches.clear();
      await _prefs.setStringList(_batchesKey, []);
    }
  }

  Future<void> resetBatches() async {
    try {
      await _prefs.remove(_batchesKey);
      _batches.clear();
      debugPrint('Batches data has been reset');
    } catch (e) {
      debugPrint('Error resetting batches: $e');
      rethrow;
    }
  }

  Future<List<Batch>> getBatches({bool activeOnly = false}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (activeOnly) {
      return _batches.where((b) => b.isActive).toList();
    }
    return List<Batch>.from(_batches);
  }

  Future<void> _saveBatches(List<Batch> batches) async {
    await _prefs.setStringList(
      _batchesKey,
      batches.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> addBatch({
    required String name,
    required int eggCount,
    required DateTime startDate,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    final batch = Batch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startDate: startDate,
      numberOfEggs: eggCount,
    );
    _batches.add(batch);
    await _saveBatches(_batches);

    // Schedule egg flipping notifications for this batch
    await FlipEggsReminder.scheduleEggFlipping(
      batchId: batch.id,
      batchName: batch.name,
    );

    // Log batch creation in history
    await _historyService.addEvent(
      HistoryEvent(
        id: DateTime.now().toString(),
        batchId: batch.id,
        batchName: batch.name,
        type: EventType.batchStart,
        status: EventStatus.success,
        description: 'Démarrage de la couvée: ${batch.name}',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> updateBatch(Batch batch) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _batches.indexWhere((b) => b.id == batch.id);
    if (index != -1) {
      _batches[index] = batch;
      await _saveBatches(_batches);
    }
  }

  Future<void> addNote(String batchId, String note) async {
    final batches = await getBatches();
    final index = batches.indexWhere((b) => b.id == batchId);

    if (index != -1) {
      final batch = batches[index];
      final updatedNotes = List<String>.from(batch.notes)..add(note);
      final updatedBatch = batch.copyWith(notes: updatedNotes);
      await updateBatch(updatedBatch);

      await _historyService.addEvent(
        HistoryEvent(
          id: DateTime.now().toString(),
          batchId: batchId,
          batchName: batch.name,
          type: EventType.note,
          status: EventStatus.info,
          description: note,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> deactivateBatch(String batchId) async {
    final batches = await getBatches();
    final index = batches.indexWhere((b) => b.id == batchId);

    if (index != -1) {
      final batch = batches[index];
      final updatedBatch = batch.copyWith(isActive: false);
      await updateBatch(updatedBatch);

      // Cancel egg flipping notifications for this batch
      await FlipEggsReminder.cancelEggFlipping(batchId);

      // Log batch deactivation in history
      await _historyService.addEvent(
        HistoryEvent(
          id: DateTime.now().toString(),
          batchId: batchId,
          batchName: batch.name,
          type: EventType.batchEnd,
          status: EventStatus.success,
          description: 'Fin de la couvée: ${batch.name}',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> deleteBatch(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    _batches.removeWhere((b) => b.id == id);
    await _saveBatches(_batches);
  }

  Future<void> startBatch(String batchName) async {
    // Log the batch start event
    await _historyService.addEvent(
      HistoryEvent(
        id: DateTime.now().toString(),
        batchId: batchName,
        batchName: batchName,
        type: EventType.batchStart,
        status: EventStatus.success,
        description: 'Démarrage de la couvée: $batchName',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> endBatch(String batchName) async {
    // Log the batch end event
    await _historyService.addEvent(
      HistoryEvent(
        id: DateTime.now().toString(),
        batchId: batchName,
        batchName: batchName,
        type: EventType.batchEnd,
        status: EventStatus.success,
        description: 'Fin de la couvée: $batchName',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> checkBatchStatus() async {
    final batches = await getBatches(activeOnly: true);

    for (final batch in batches) {
      final currentTemp = await getCurrentTemperature();
      final currentHumidity = await getCurrentHumidity();

      // Check temperature and humidity using alert service
      await _alertService.checkTemperature(currentTemp, batch.id);
      await _alertService.checkHumidity(currentHumidity, batch.id);

      final tempAdjusted = await adjustTemperature(batch, currentTemp);
      final humidityAdjusted = await adjustHumidity(batch, currentHumidity);

      if (tempAdjusted || humidityAdjusted) {
        await _historyService.addEvent(
          HistoryEvent(
            id: DateTime.now().toString(),
            batchId: batch.id,
            batchName: batch.name,
            type: EventType.systemEvent,
            status: EventStatus.success,
            description:
                'Régulation automatique - ${tempAdjusted ? 'Température ' : ''}${humidityAdjusted ? 'Humidité' : ''}ajustée',
            timestamp: DateTime.now(),
            additionalData: {
              'temperature': currentTemp,
              'humidity': currentHumidity,
            },
          ),
        );
      }
    }
  }

  // Mock implementations for sensor-related methods
  Future<double> getCurrentTemperature() async {
    // Implementation needed
    return 37.5; // Mock value
  }

  Future<double> getCurrentHumidity() async {
    // Implementation needed
    return 65.0; // Mock value
  }

  Future<bool> adjustTemperature(Batch batch, double currentTemp) async {
    // Implementation needed
    return false; // Mock value
  }

  Future<bool> adjustHumidity(Batch batch, double currentHumidity) async {
    // Implementation needed
    return false; // Mock value
  }

  Future<void> addTestBatch() async {
    // Create a batch that started 21 days ago
    final startDate = DateTime.now().subtract(const Duration(days: 21));
    final batch = Batch(
      id: 'test_batch_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Couvée',
      startDate: startDate,
      numberOfEggs: 12,
      isActive: true,
      notes: ['Couvée test créée pour le questionnaire'],
    );
    _batches.add(batch);
    await _saveBatches(_batches);

    // Log batch creation in history
    await _historyService.addEvent(
      HistoryEvent(
        id: DateTime.now().toString(),
        batchId: batch.id,
        batchName: batch.name,
        type: EventType.batchStart,
        status: EventStatus.success,
        description: 'Démarrage de la couvée test: ${batch.name}',
        timestamp: startDate,
      ),
    );

    // Add a note to indicate it's ready for questionnaire
    await addNote(
      batch.id,
      'Cette couvée est prête pour le questionnaire final.',
    );
  }
}
