// lib/screens/components_page.dart

import 'package:flutter/material.dart';
import '../models/component.dart';
import '../services/component_service.dart';

class ComponentsPage extends StatefulWidget {
  final ComponentService componentService;

  const ComponentsPage({super.key, required this.componentService});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  List<Component> _components = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    try {
      final components = await widget.componentService.getComponents();
      if (mounted) {
        setState(() {
          _components = components;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Composants')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadComponents,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _components.length,
                  itemBuilder: (context, index) {
                    final component = _components[index];
                    final needsReplacement = component.needsReplacement;
                    final remainingDays = component.remainingDays;

                    return Card(
                      color: needsReplacement ? Colors.red[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              needsReplacement
                                  ? Colors.red.withAlpha(26)
                                  : Colors.blue.withAlpha(26),
                          child: Icon(
                            _getComponentIcon(component.name),
                            color: needsReplacement ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(component.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durée de vie restante: $remainingDays jours',
                              style: TextStyle(
                                color:
                                    needsReplacement
                                        ? Colors.red
                                        : Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Installé le: ${_formatDate(component.installationDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          color: needsReplacement ? Colors.red : Colors.blue,
                          onPressed: () async {
                            await widget.componentService.replaceComponent(
                              component.id,
                            );
                            await _loadComponents();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  IconData _getComponentIcon(String componentName) {
    switch (componentName.toLowerCase()) {
      case 'carte st':
        return Icons.memory;
      case 'capteurs':
        return Icons.sensors;
      case 'ventilateur':
        return Icons.wind_power;
      case 'lampe':
        return Icons.lightbulb;
      default:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
