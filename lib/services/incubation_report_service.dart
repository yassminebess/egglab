import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/incubation_report.dart';
import 'package:flutter/foundation.dart';

class IncubationReportService {
  final SharedPreferences _prefs;
  static const String _reportsKey = 'incubation_reports';
  final _reportsController =
      StreamController<List<IncubationReport>>.broadcast();

  IncubationReportService(this._prefs);

  Stream<List<IncubationReport>> get reportsStream => _reportsController.stream;

  Future<void> saveReport(IncubationReport report) async {
    debugPrint('IncubationReportService: Saving report ${report.id}');
    final reports = await getReports();
    debugPrint(
        'IncubationReportService: Current reports count: ${reports.length}');
    reports.add(report);
    await _saveReports(reports);
    debugPrint('IncubationReportService: Report saved successfully');
  }

  Future<void> deleteReport(String reportId) async {
    debugPrint('IncubationReportService: Deleting report $reportId');
    final reports = await getReports();
    reports.removeWhere((report) => report.id == reportId);
    await _saveReports(reports);
    debugPrint('IncubationReportService: Report deleted successfully');
  }

  Future<void> deleteAllReports() async {
    debugPrint('IncubationReportService: Deleting all reports');
    await _prefs.remove(_reportsKey);
    _reportsController.add([]);
    debugPrint('IncubationReportService: All reports deleted successfully');
  }

  Future<void> _saveReports(List<IncubationReport> reports) async {
    debugPrint('IncubationReportService: Saving ${reports.length} reports');
    final reportsJson = jsonEncode(reports.map((r) => r.toJson()).toList());
    await _prefs.setString(_reportsKey, reportsJson);
    _reportsController.add(reports);
    debugPrint('IncubationReportService: Reports saved successfully');
  }

  Future<List<IncubationReport>> getReports() async {
    debugPrint('IncubationReportService: Getting reports');
    final reportsJson = _prefs.getString(_reportsKey);
    if (reportsJson == null) {
      debugPrint('IncubationReportService: No reports found');
      return [];
    }

    final List<dynamic> reportsList = jsonDecode(reportsJson);
    final reports =
        reportsList.map((json) => IncubationReport.fromJson(json)).toList();
    debugPrint('IncubationReportService: Found ${reports.length} reports');
    return reports;
  }

  Future<bool> hasReport(String batchId) async {
    final reports = await getReports();
    return reports.any((report) => report.batchId == batchId);
  }

  Future<void> deleteReportsForBatch(String batchId) async {
    debugPrint('IncubationReportService: Deleting reports for batch $batchId');
    final reports = await getReports();
    reports.removeWhere((report) => report.batchId == batchId);
    await _saveReports(reports);
    debugPrint('IncubationReportService: Reports for batch $batchId deleted');
  }

  void dispose() {
    _reportsController.close();
  }
}
