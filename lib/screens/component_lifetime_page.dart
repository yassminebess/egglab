import 'package:flutter/material.dart';

class ComponentLifetimePage extends StatelessWidget {
  const ComponentLifetimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Durée de Vie des Composants'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildComponentCard(
            'Ventilateur',
            'Durée de vie estimée: 12 mois',
            Icons.air,
            const Duration(days: 365),
            DateTime(2024, 1, 1),
          ),
          const SizedBox(height: 16),
          _buildComponentCard(
            'Capteur de température',
            'Durée de vie estimée: 24 mois',
            Icons.thermostat,
            const Duration(days: 730),
            DateTime(2024, 1, 1),
          ),
          const SizedBox(height: 16),
          _buildComponentCard(
            'Capteur d\'humidité',
            'Durée de vie estimée: 24 mois',
            Icons.water_drop,
            const Duration(days: 730),
            DateTime(2024, 1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(
    String title,
    String subtitle,
    IconData icon,
    Duration lifetime,
    DateTime installationDate,
  ) {
    final now = DateTime.now();
    final elapsedDays = now.difference(installationDate).inDays;
    final progress = elapsedDays / lifetime.inDays;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                progress > 0.8 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Installé le: ${_formatDate(installationDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
