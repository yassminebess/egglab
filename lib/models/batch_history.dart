class BatchHistoryEvent {
  final String batchId;
  final DateTime timestamp;
  final String eventType;
  final String description;

  BatchHistoryEvent({
    required this.batchId,
    required this.timestamp,
    required this.eventType,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'description': description,
  };

  factory BatchHistoryEvent.fromJson(Map<String, dynamic> json) => BatchHistoryEvent(
    batchId: json['batchId'],
    timestamp: DateTime.parse(json['timestamp']),
    eventType: json['eventType'],
    description: json['description'],
  );
}

class BatchHistory {
  final String batchId;
  final List<BatchHistoryEvent> events;

  BatchHistory({
    required this.batchId,
    required this.events,
  });

  void addEvent(String eventType, String description) {
    events.add(BatchHistoryEvent(
      batchId: batchId,
      timestamp: DateTime.now(),
      eventType: eventType,
      description: description,
    ));
  }

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory BatchHistory.fromJson(Map<String, dynamic> json) => BatchHistory(
    batchId: json['batchId'],
    events: (json['events'] as List)
        .map((e) => BatchHistoryEvent.fromJson(e))
        .toList(),
  );

  factory BatchHistory.create(String batchId) => BatchHistory(
    batchId: batchId,
    events: [],
  );
} 