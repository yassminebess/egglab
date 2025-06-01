import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/incubation_report.dart';

class IncubationReportForm extends StatefulWidget {
  final String batchId;
  final String batchName;
  final Function(IncubationReport) onSubmit;

  const IncubationReportForm({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.onSubmit,
  });

  @override
  State<IncubationReportForm> createState() => _IncubationReportFormState();
}

class _IncubationReportFormState extends State<IncubationReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _totalEggsController = TextEditingController();
  final _hatchedChicksController = TextEditingController();
  final _problemDescriptionController = TextEditingController();
  final _additionalCommentsController = TextEditingController();

  bool _hadProblems = false;
  bool _consistentEnvironment = true;
  int _rating = 5;

  @override
  void dispose() {
    _totalEggsController.dispose();
    _hatchedChicksController.dispose();
    _problemDescriptionController.dispose();
    _additionalCommentsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final report = IncubationReport(
        id: const Uuid().v4(),
        batchId: widget.batchId,
        batchName: widget.batchName,
        submissionDate: DateTime.now(),
        totalEggs: int.parse(_totalEggsController.text),
        hatchedChicks: int.parse(_hatchedChicksController.text),
        hadProblems: _hadProblems,
        problemDescription:
            _hadProblems ? _problemDescriptionController.text : null,
        consistentEnvironment: _consistentEnvironment,
        rating: _rating,
        additionalComments: _additionalCommentsController.text.isNotEmpty
            ? _additionalCommentsController.text
            : null,
      );
      widget.onSubmit(report);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rapport d\'incubation',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Total Eggs
            TextFormField(
              controller: _totalEggsController,
              decoration: const InputDecoration(
                labelText: 'Nombre d\'œufs placés',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nombre d\'œufs';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hatched Chicks
            TextFormField(
              controller: _hatchedChicksController,
              decoration: const InputDecoration(
                labelText: 'Nombre de poussins éclos',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nombre de poussins';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                final total = int.tryParse(_totalEggsController.text) ?? 0;
                final hatched = int.tryParse(value) ?? 0;
                if (hatched > total) {
                  return 'Le nombre de poussins ne peut pas dépasser le nombre d\'œufs';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Problems
            SwitchListTile(
              title: const Text('Problèmes rencontrés'),
              value: _hadProblems,
              onChanged: (value) => setState(() => _hadProblems = value),
            ),
            if (_hadProblems) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _problemDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description des problèmes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_hadProblems && (value == null || value.isEmpty)) {
                    return 'Veuillez décrire les problèmes rencontrés';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            // Environment Consistency
            SwitchListTile(
              title: const Text('Contrôle de température et humidité constant'),
              value: _consistentEnvironment,
              onChanged: (value) =>
                  setState(() => _consistentEnvironment = value),
            ),
            const SizedBox(height: 16),

            // Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Note globale'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = index + 1),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional Comments
            TextFormField(
              controller: _additionalCommentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires additionnels (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enregistrer le rapport'),
            ),
          ],
        ),
      ),
    );
  }
}
