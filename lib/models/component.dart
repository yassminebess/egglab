// lib/models/component.dart

class Component {
  final String id;
  final String name;
  final DateTime installationDate;
  final int expectedLifespanDays;

  Component({
    required this.id,
    required this.name,
    required this.installationDate,
    required this.expectedLifespanDays,
  });

  int get remainingDays {
    final now = DateTime.now();
    final endDate = installationDate.add(Duration(days: expectedLifespanDays));
    return endDate.difference(now).inDays;
  }

  bool get needsReplacement => remainingDays <= 21;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'installationDate': installationDate.toIso8601String(),
      'expectedLifespanDays': expectedLifespanDays,
    };
  }

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'],
      name: json['name'],
      installationDate: DateTime.parse(json['installationDate']),
      expectedLifespanDays: json['expectedLifespanDays'],
    );
  }

  static List<Component> getDefaultComponents() {
    return [
      Component(
        id: 'st_board',
        name: 'Carte ST',
        installationDate: DateTime.now(),
        expectedLifespanDays: 365, // 1 year
      ),
      Component(
        id: 'sensors',
        name: 'Capteurs',
        installationDate: DateTime.now(),
        expectedLifespanDays: 180, // 6 months
      ),
      Component(
        id: 'fan',
        name: 'Ventilateur',
        installationDate: DateTime.now(),
        expectedLifespanDays: 270, // 9 months
      ),
      Component(
        id: 'lamp',
        name: 'Lampe',
        installationDate: DateTime.now(),
        expectedLifespanDays: 90, // 3 months
      ),
    ];
  }
}
