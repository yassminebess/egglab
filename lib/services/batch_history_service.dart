import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch_history.dart';

class BatchHistoryService {
  static const String _storageKey = 'batch_histories';

  Future<BatchHistory> getHistory(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historiesJson = prefs.getString(_storageKey);
    
    if (historiesJson == null) {
      return BatchHistory.create(batchId);
    }

    final List<dynamic> histories = json.decode(historiesJson);
    final historyJson = histories.firstWhere(
      (h) => h['batchId'] == batchId,
      orElse: () => {'batchId': batchId, 'events': []},
    );

    return BatchHistory.fromJson(historyJson);
  }

  Future<void> saveHistory(BatchHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historiesJson = prefs.getString(_storageKey);
    List<dynamic> histories = [];

    if (historiesJson != null) {
      histories = json.decode(historiesJson);
      final index = histories.indexWhere((h) => h['batchId'] == history.batchId);
      if (index >= 0) {
        histories[index] = history.toJson();
      } else {
        histories.add(history.toJson());
      }
    } else {
      histories.add(history.toJson());
    }

    await prefs.setString(_storageKey, json.encode(histories));
  }

  Future<void> addEvent(
    String batchId,
    String eventType,
    String description,
  ) async {
    final history = await getHistory(batchId);
    history.addEvent(eventType, description);
    await saveHistory(history);
  }

  Future<void> deleteBatchHistory(String batchId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historiesJson = prefs.getString(_storageKey);
    
    if (historiesJson != null) {
      final List<dynamic> histories = json.decode(historiesJson);
      histories.removeWhere((h) => h['batchId'] == batchId);
      await prefs.setString(_storageKey, json.encode(histories));
    }
  }
} 