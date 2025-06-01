import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/history_event.dart';

class HistoryService {
  final SharedPreferences _prefs;
  static const String _historyKeyPrefix = 'history_events_';

  HistoryService(this._prefs);

  String _getHistoryKey(String? batchId) {
    return batchId != null ? '$_historyKeyPrefix$batchId' : _historyKeyPrefix;
  }

  Future<List<HistoryEvent>> getHistoryEvents({String? batchId}) async {
    List<HistoryEvent> allEvents = [];

    if (batchId != null) {
      // Get events for specific batch
      final String? eventsJson = _prefs.getString(_getHistoryKey(batchId));
      if (eventsJson != null) {
        List<dynamic> eventsList = jsonDecode(eventsJson);
        allEvents = eventsList.map((e) => _fromJson(e)).toList();
      }
    } else {
      // Get all events from all batches
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_historyKeyPrefix));
      for (final key in keys) {
        final String? eventsJson = _prefs.getString(key);
        if (eventsJson != null) {
          List<dynamic> eventsList = jsonDecode(eventsJson);
          allEvents.addAll(eventsList.map((e) => _fromJson(e)).toList());
        }
      }
    }

    allEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEvents;
  }

  Future<void> addEvent(HistoryEvent event) async {
    final key = _getHistoryKey(event.batchId);
    List<HistoryEvent> events = await getHistoryEvents(batchId: event.batchId);
    events.add(event);
    await _saveEvents(events, key);
  }

  Future<void> _saveEvents(List<HistoryEvent> events, String key) async {
    List<Map<String, dynamic>> eventMaps =
        events.map((e) => _toJson(e)).toList();
    await _prefs.setString(key, jsonEncode(eventMaps));
  }

  Map<String, dynamic> _toJson(HistoryEvent event) {
    return {
      'id': event.id,
      'batchId': event.batchId,
      'batchName': event.batchName,
      'type': event.type.toString(),
      'status': event.status.toString(),
      'description': event.description,
      'timestamp': event.timestamp.toIso8601String(),
      'additionalData': event.additionalData,
    };
  }

  HistoryEvent _fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      batchName: json['batchName'] as String,
      type: EventType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      status: EventStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'],
    );
  }

  Future<void> clearHistory({String? batchId}) async {
    if (batchId == null) {
      // Clear all history
      final keys =
          _prefs.getKeys().where((key) => key.startsWith(_historyKeyPrefix));
      for (final key in keys) {
        await _prefs.remove(key);
      }
    } else {
      // Clear history for specific batch
      await _prefs.remove(_getHistoryKey(batchId));
    }
  }

  Future<List<String>> getBatchIds() async {
    final events = await getHistoryEvents();
    final batchIds = events.map((e) => e.batchId).toSet().toList();
    return batchIds;
  }

  Future<Map<String, String>> getBatchNamesMap() async {
    final events = await getHistoryEvents();
    final Map<String, String> batchNamesMap = {};

    for (final event in events) {
      if (!batchNamesMap.containsKey(event.batchId)) {
        batchNamesMap[event.batchId] = event.batchName;
      }
    }

    return batchNamesMap;
  }

  Future<List<MapEntry<String, String>>> getBatchNamesEntries() async {
    final batchMap = await getBatchNamesMap();
    final entries = batchMap.entries.toList();
    // Sort by batch name alphabetically
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }
}
