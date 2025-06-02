import 'package:flutter/material.dart';
import '../services/incubation_report_service.dart';
import '../models/incubation_report.dart';

class BatchReportsPage extends StatefulWidget {
  final String batchId;
  final String batchName;
  final IncubationReportService reportService;

  const BatchReportsPage({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.reportService,
  });

  @override
  State<BatchReportsPage> createState() => _BatchReportsPageState();
}

class _BatchReportsPageState extends State<BatchReportsPage> {
  List<IncubationReport> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final allReports = await widget.reportService.getReports();
      final reports =
          allReports.where((r) => r.batchId == widget.batchId).toList();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des rapports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapports: ${widget.batchName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Text('Aucun rapport/questionnaire pour cette couvée.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soumis le: '
                              '${report.submissionDate.day}/${report.submissionDate.month}/${report.submissionDate.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text('Œufs placés: ${report.totalEggs ?? '-'}'),
                            Text(
                                'Poussins éclos: ${report.hatchedChicks ?? '-'}'),
                            Text(
                                'Taux de réussite: ${report.hatchRate.toStringAsFixed(1)}%'),
                            if (report.hadProblems == true &&
                                (report.problemDescription ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Problèmes: ${report.problemDescription!}',
                                  style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 8),
                            Text(
                                'Contrôle environnement: ${report.consistentEnvironment ? 'Oui' : 'Non'}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Note: '),
                                ...List.generate(
                                    5,
                                    (i) => Icon(
                                          i < (report.rating ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        )),
                              ],
                            ),
                            if (report.additionalComments != null &&
                                report.additionalComments!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Commentaire: ${report.additionalComments!}',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
