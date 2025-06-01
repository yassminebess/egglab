import 'package:flutter/material.dart';

enum EventType {
  alert,
  note,
  eggFlipping,
  batchStart,
  batchEnd,
  manualOverride,
  systemEvent,
}

enum EventStatus {
  info,
  warning,
  critical,
  success,
  manual,
}

class HistoryEvent {
  final String id;
  final String batchId;
  final String batchName;
  final EventType type;
  final EventStatus status;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  const HistoryEvent({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.type,
    required this.status,
    required this.description,
    required this.timestamp,
    this.additionalData,
  });

  IconData get icon {
    switch (type) {
      case EventType.eggFlipping:
        return Icons.rotate_right;
      case EventType.systemEvent:
        return Icons.auto_mode;
      case EventType.manualOverride:
        return Icons.pan_tool;
      case EventType.batchStart:
        return Icons.play_circle;
      case EventType.batchEnd:
        return Icons.stop_circle;
      case EventType.alert:
        return Icons.warning;
      case EventType.note:
        return Icons.note;
    }
  }

  Color getStatusColor(BuildContext context) {
    switch (status) {
      case EventStatus.success:
        return Colors.green;
      case EventStatus.manual:
        return Colors.orange;
      case EventStatus.info:
        return Colors.blue;
      case EventStatus.warning:
        return Colors.yellow;
      case EventStatus.critical:
        return Colors.red;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'batchName': batchName,
      'type': type.toString(),
      'status': status.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      batchName: json['batchName'] as String,
      type: EventType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}
