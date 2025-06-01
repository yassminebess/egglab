enum AlertType {
  temperature,
  humidity,
  eggFlipping,
  componentLifespan,
  sensorFailure,
  fanMalfunction,
  lampMalfunction,
  manualOverride,
}

class Alert {
  final String id;
  final AlertType type;
  final String message;
  final DateTime timestamp;
  final String? batchId;
  final bool isResolved;

  const Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.batchId,
    this.isResolved = false,
  });

  Alert copyWith({
    String? id,
    AlertType? type,
    String? message,
    DateTime? timestamp,
    String? batchId,
    bool? isResolved,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      batchId: batchId ?? this.batchId,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'batchId': batchId,
      'isResolved': isResolved,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      batchId: json['batchId'] as String?,
      isResolved: json['isResolved'] as bool,
    );
  }
}
