class Batch {
  final String id;
  final String name;
  final DateTime startDate;
  final int numberOfEggs;
  final List<String> notes;
  final bool isActive;

  Batch({
    required this.id,
    required this.name,
    required this.startDate,
    required this.numberOfEggs,
    this.notes = const [],
    this.isActive = true,
  });

  int get daysSinceStart => DateTime.now().difference(startDate).inDays + 1;

  bool get isHatchingNear {
    const int hatchingDays = 21;
    final daysLeft = hatchingDays - daysSinceStart;
    return daysLeft <= 2 && daysLeft > 0;
  }

  Batch copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? numberOfEggs,
    List<String>? notes,
    bool? isActive,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      numberOfEggs: numberOfEggs ?? this.numberOfEggs,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'numberOfEggs': numberOfEggs,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      numberOfEggs: json['numberOfEggs'] as int,
      notes: List<String>.from(json['notes'] as List),
      isActive: json['isActive'] as bool,
    );
  }

  factory Batch.create(String name) {
    return Batch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startDate: DateTime.now(),
      numberOfEggs: 0,
    );
  }
}
