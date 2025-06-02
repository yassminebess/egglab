class IncubationReport {
  final String id;
  final String batchId;
  final String batchName;
  final DateTime submissionDate;
  final int totalEggs;
  final int hatchedChicks;
  final bool hadProblems;
  final String? problemDescription;
  final bool consistentEnvironment;
  final int rating;
  final String? additionalComments;

  const IncubationReport({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.submissionDate,
    required this.totalEggs,
    required this.hatchedChicks,
    required this.hadProblems,
    this.problemDescription,
    required this.consistentEnvironment,
    required this.rating,
    this.additionalComments,
  });

  double get hatchRate => totalEggs > 0 ? (hatchedChicks / totalEggs) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'batchName': batchName,
      'submissionDate': submissionDate.toIso8601String(),
      'totalEggs': totalEggs,
      'hatchedChicks': hatchedChicks,
      'hadProblems': hadProblems,
      'problemDescription': problemDescription,
      'consistentEnvironment': consistentEnvironment,
      'rating': rating,
      'additionalComments': additionalComments,
    };
  }

  factory IncubationReport.fromJson(Map<String, dynamic> json) {
    return IncubationReport(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      batchName: json['batchName'] as String,
      submissionDate: DateTime.parse(json['submissionDate'] as String),
      totalEggs: json['totalEggs'] as int,
      hatchedChicks: json['hatchedChicks'] as int,
      hadProblems: json['hadProblems'] as bool,
      problemDescription: json['problemDescription'] as String?,
      consistentEnvironment: json['consistentEnvironment'] as bool,
      rating: json['rating'] as int,
      additionalComments: json['additionalComments'] as String?,
    );
  }
}
