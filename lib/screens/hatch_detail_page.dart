import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';
import '../services/alert_service.dart';
import '../services/history_service.dart';
import '../widgets/incubation_progress.dart';
import '../widgets/sensor_graph.dart';
import '../services/sensor_data_service.dart';
import '../widgets/egg_flip_countdown.dart';
import 'timeline_tile_custom.dart';

class HatchDetailPage extends StatefulWidget {
  final Batch batch;
  final BatchService batchService;
  final AlertService alertService;
  final HistoryService historyService;
  final SensorDataService sensorService;

  const HatchDetailPage({
    super.key,
    required this.batch,
    required this.batchService,
    required this.alertService,
    required this.historyService,
    required this.sensorService,
  });

  @override
  State<HatchDetailPage> createState() => _HatchDetailPageState();
}

class _HatchDetailPageState extends State<HatchDetailPage> {
  bool _isMonitoring = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _timelineEvents = [];
  List<Map<String, dynamic>> _visibleEvents = [];
  bool _isDisposed = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HatchDetailPage: Initializing for batch ${widget.batch.name}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitialize();
    });
  }

  Future<void> _safeInitialize() async {
    if (_isDisposed) return;

    try {
      // Stop any existing monitoring first
      widget.sensorService.stopMonitoring();

      await _initializeTimelineEvents();
      if (_isDisposed) return;

      await _initializeMonitoring();
      if (_isDisposed) return;

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error during initialization: $e\n$stackTrace');
      if (!_isDisposed && mounted) {
        setState(() {
          _errorMessage = 'Erreur d\'initialisation: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeTimelineEvents() async {
    if (_isDisposed) return;

    try {
      final now = DateTime.now();
      _timelineEvents = [
        {
          'title': 'Début de la couvée',
          'date': widget.batch.startDate,
          'before': (days) => '$days jours restants',
          'after': 'Couvée commencée',
        },
        {
          'title': 'Date de mirage',
          'date': widget.batch.startDate.add(const Duration(days: 7)),
          'before': (days) => '$days jours restants',
          'after': 'Mirage effectué',
        },
        {
          'title': 'Début de l\'éclosoir',
          'date': widget.batch.startDate.add(const Duration(days: 18)),
          'before': (days) => '$days jours restants',
          'after': 'Éclosoir commencé',
        },
        {
          'title': 'Sortie des poussins',
          'date': widget.batch.startDate.add(const Duration(days: 21)),
          'before': (days) => '$days jours restants',
          'after': 'Sortie terminée',
        },
      ];

      // Simple, safe logic: show all events, mark past/future in UI only
      _visibleEvents = List<Map<String, dynamic>>.from(_timelineEvents);
      debugPrint('Timeline events initialized: \\n$_visibleEvents');
    } catch (e, stackTrace) {
      debugPrint('Error initializing timeline events: $e\\n$stackTrace');
      _visibleEvents = [];
    }
  }

  Future<void> _initializeMonitoring() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          'HatchDetailPage: Starting monitoring for batch ${widget.batch.name}');

      // Start new monitoring
      await widget.sensorService.startMonitoring(
        widget.batch.id,
        widget.batch.name,
        startDate: widget.batch.startDate,
      );

      if (_isDisposed) return;

      if (mounted) {
        setState(() {
          _isMonitoring = true;
          _isLoading = false;
        });
      }
      debugPrint('HatchDetailPage: Monitoring started successfully');
    } catch (e, stackTrace) {
      debugPrint('HatchDetailPage: Error starting monitoring: $e');
      debugPrint('Stack trace: $stackTrace');
      if (_isDisposed) return;

      if (mounted) {
        setState(() {
          _isMonitoring = false;
          _isLoading = false;
          _errorMessage = 'Erreur de surveillance: $e';
        });
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: () => _initializeMonitoring(),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    debugPrint('HatchDetailPage: Disposing for batch ${widget.batch.name}');
    _isDisposed = true;
    widget.sensorService.stopMonitoring();
    super.dispose();
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _stopMonitoring();
    } else {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    if (_isDisposed) return;
    debugPrint('HatchDetailPage: Starting monitoring');
    setState(() => _isLoading = true);
    _initializeMonitoring();
  }

  void _stopMonitoring() {
    if (_isDisposed) return;
    debugPrint('HatchDetailPage: Stopping monitoring');
    setState(() => _isMonitoring = false);
    try {
      widget.sensorService.stopMonitoring();
    } catch (e) {
      debugPrint('HatchDetailPage: Error stopping monitoring: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildSensorGraph(
      Stream<List<SensorDataPoint>> stream,
      String title,
      String unit,
      double minThreshold,
      double maxThreshold,
      Color normalColor,
      Color alertColor) {
    return StreamBuilder<List<SensorDataPoint>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Sensor graph error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Erreur de connexion: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _initializeMonitoring(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Chargement des données...'),
              ],
            ),
          );
        }
        return Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SensorGraph(
                dataPoints: snapshot.data!,
                title: title,
                unit: unit,
                minThreshold: minThreshold,
                maxThreshold: maxThreshold,
                normalColor: normalColor,
                alertColor: alertColor,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.batch.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.batch.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.batch.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeMonitoring,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        widget.sensorService.stopMonitoring();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.sensorService.stopMonitoring();
              Navigator.of(context).pop();
            },
          ),
          title: Text(widget.batch.name),
          actions: [
            IconButton(
              icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleMonitoring,
              tooltip: _isMonitoring
                  ? 'Arrêter la surveillance'
                  : 'Démarrer la surveillance',
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _safeInitialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 24.0),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: IncubationProgress(
                      startDate: widget.batch.startDate,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: EggFlipCountdown(
                      batchId: widget.batch.id,
                      batchName: widget.batch.name,
                      onFlip: () {
                        if (!_isDisposed && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Retournement des oeufs enregistré !'),
                              backgroundColor: Colors.amber,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 16),
                  // Sensor Graphs
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: _buildSensorGraph(
                            widget.sensorService.temperatureStream,
                            'Température',
                            '°C',
                            SensorDataService.minTemp,
                            SensorDataService.maxTemp,
                            Colors.red,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _buildSensorGraph(
                            widget.sensorService.humidityStream,
                            'Humidité',
                            '%',
                            SensorDataService.minHumidity,
                            SensorDataService.maxHumidity,
                            Colors.blue,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      height: 350,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleEvents.length,
                        itemBuilder: (context, i) {
                          final event = _visibleEvents[i];
                          final eventDate = event['date'] as DateTime;
                          final isLast = i == _visibleEvents.length - 1;
                          final daysDiff =
                              eventDate.difference(DateTime.now()).inDays;
                          final isPast = DateTime.now().isAfter(eventDate);
                          String subtitle;
                          if (isPast) {
                            subtitle =
                                event['after'] is String ? event['after'] : '';
                          } else {
                            subtitle = event['before'] is Function
                                ? event['before'](daysDiff)
                                : '';
                          }
                          return CustomTimelineTile(
                            title: event['title'] as String,
                            date: eventDate,
                            currentDay: 0,
                            totalDays: 0,
                            isCompleted: isPast,
                            isLast: isLast,
                            subtitle: subtitle,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
