import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/component.dart';
import '../models/alert.dart';
import 'alert_service.dart';

class ComponentService {
  static const String _componentsKey = 'components';
  final SharedPreferences _prefs;
  final AlertService _alertService;
  final _uuid = const Uuid();

  ComponentService(this._prefs, this._alertService);

  Future<List<Component>> getComponents() async {
    final componentsJson = _prefs.getStringList(_componentsKey);
    if (componentsJson == null || componentsJson.isEmpty) {
      // Initialize with default components if none exist
      final defaultComponents = Component.getDefaultComponents();
      await _saveComponents(defaultComponents);
      return defaultComponents;
    }

    return componentsJson
        .map((json) => Component.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveComponents(List<Component> components) async {
    await _prefs.setStringList(
      _componentsKey,
      components.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> addComponent(String name, int expectedLifespanDays) async {
    final component = Component(
      id: _uuid.v4(),
      name: name,
      installationDate: DateTime.now(),
      expectedLifespanDays: expectedLifespanDays,
    );

    final components = await getComponents();
    components.add(component);
    await _saveComponents(components);
  }

  Future<void> replaceComponent(String componentId) async {
    final components = await getComponents();
    final index = components.indexWhere((c) => c.id == componentId);

    if (index != -1) {
      final oldComponent = components[index];
      final newComponent = Component(
        id: _uuid.v4(),
        name: oldComponent.name,
        installationDate: DateTime.now(),
        expectedLifespanDays: oldComponent.expectedLifespanDays,
      );

      components[index] = newComponent;
      await _saveComponents(components);
    }
  }

  Future<void> checkComponentLifespans() async {
    final components = await getComponents();
    for (final component in components) {
      if (component.needsReplacement) {
        await _alertService.addAlert(
          AlertType.componentLifespan,
          '${component.name} doit être remplacé dans ${component.remainingDays} jours',
          'system',
        );
      }
    }
  }
}
