import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import 'alert_service.dart';
import 'history_service.dart';
import 'batch_service.dart';

class SensorDataPoint {
  final DateTime timestamp;
  final double value;
  final bool isAlert;

  const SensorDataPoint({
    required this.timestamp,
    required this.value,
    this.isAlert = false,
  });
}

class SensorDataService {
  static const double minTemp = 37.2;
  static const double maxTemp = 38.2;
  static const double minHumidity = 50.0;
  static const double maxHumidity = 60.0;

  final AlertService alertService;
  final BatchService batchService;
  final HistoryService historyService;

  final _temperatureController =
      StreamController<List<SensorDataPoint>>.broadcast();
  final _humidityController =
      StreamController<List<SensorDataPoint>>.broadcast();

  Timer? _timer;
  String? _currentBatchId;
  String? _currentBatchName;
  DateTime? _startDate;
  final List<SensorDataPoint> _temperatureHistory = [];
  final List<SensorDataPoint> _humidityHistory = [];
  bool _isInitialized = false;
  bool _isDisposed = false;

  Stream<List<SensorDataPoint>> get temperatureStream =>
      _temperatureController.stream;
  Stream<List<SensorDataPoint>> get humidityStream =>
      _humidityController.stream;

  SensorDataService(this.alertService, this.batchService, this.historyService);

  Future<void> startMonitoring(String batchId, String batchName,
      {required DateTime startDate}) async {
    if (_isDisposed) return;

    try {
      debugPrint('Starting monitoring for batch: $batchName');

      // Only stop if we're monitoring a different batch
      if (_currentBatchId != null && _currentBatchId != batchId) {
        await _stopMonitoring();
      }

      // If we're already monitoring this batch, don't restart
      if (_currentBatchId == batchId && _isInitialized) {
        debugPrint('Already monitoring batch: $batchName');
        return;
      }

      _currentBatchId = batchId;
      _currentBatchName = batchName;
      _startDate = startDate;
      _isInitialized = false;

      // Generate initial data points
      await _generateInitialDataPoints();

      // Generate first data point immediately
      await _generateDataPoint();

      // Start generating new data points every 10 minutes
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        _generateDataPoint();
      });

      // Notify listeners of initial data
      if (!_temperatureController.isClosed && _temperatureHistory.isNotEmpty) {
        _temperatureController
            .add(List<SensorDataPoint>.from(_temperatureHistory));
      }
      if (!_humidityController.isClosed && _humidityHistory.isNotEmpty) {
        _humidityController.add(List<SensorDataPoint>.from(_humidityHistory));
      }

      _isInitialized = true;
      debugPrint('Monitoring initialized successfully for batch: $batchName');
    } catch (e, stackTrace) {
      debugPrint('Error starting monitoring: $e\n$stackTrace');
      _handleError('Error starting monitoring: $e');
      rethrow;
    }
  }

  Future<void> _stopMonitoring() async {
    if (_isDisposed) return;

    debugPrint('Stopping monitoring for batch: $_currentBatchName');
    _timer?.cancel();
    _timer = null;
    _currentBatchId = null;
    _currentBatchName = null;
    _startDate = null;
    _isInitialized = false;
    _temperatureHistory.clear();
    _humidityHistory.clear();
  }

  void stopMonitoring() {
    _stopMonitoring();
  }

  Future<void> _generateInitialDataPoints() async {
    if (_startDate == null || _isDisposed) return;

    try {
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      debugPrint(
          'Generating data points from ${twoHoursAgo.toString()} to ${now.toString()}');

      _temperatureHistory.clear();
      _humidityHistory.clear();

      // Generate data points every 10 minutes for the last 2 hours
      DateTime currentTime = twoHoursAgo;
      while (!currentTime.isAfter(now)) {
        if (_isDisposed) return;

        final temp = _generateRandomValue(minTemp, maxTemp);
        _temperatureHistory.add(SensorDataPoint(
          timestamp: currentTime,
          value: temp,
          isAlert: temp < minTemp || temp > maxTemp,
        ));

        final humidity = _generateRandomValue(minHumidity, maxHumidity);
        _humidityHistory.add(SensorDataPoint(
          timestamp: currentTime,
          value: humidity,
          isAlert: humidity < minHumidity || humidity > maxHumidity,
        ));

        // Move to next 10-minute interval
        currentTime = currentTime.add(const Duration(minutes: 10));
      }

      // Add current data point
      final currentTemp = _generateRandomValue(minTemp, maxTemp);
      _temperatureHistory.add(SensorDataPoint(
        timestamp: now,
        value: currentTemp,
        isAlert: currentTemp < minTemp || currentTemp > maxTemp,
      ));

      final currentHumidity = _generateRandomValue(minHumidity, maxHumidity);
      _humidityHistory.add(SensorDataPoint(
        timestamp: now,
        value: currentHumidity,
        isAlert: currentHumidity < minHumidity || currentHumidity > maxHumidity,
      ));

      // Sort data points by timestamp
      _temperatureHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _humidityHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint(
          'Generated ${_temperatureHistory.length} data points successfully');
    } catch (e, stackTrace) {
      debugPrint('Error generating initial data points: $e\n$stackTrace');
      _handleError('Error generating initial data: $e');
      rethrow;
    }
  }

  Future<void> _generateDataPoint() async {
    if (_isDisposed || !_isInitialized) return;

    try {
      if (_currentBatchId == null || _currentBatchName == null) {
        debugPrint('Cannot generate data point: No active batch');
        return;
      }

      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      // Remove old data points
      _temperatureHistory
          .removeWhere((point) => point.timestamp.isBefore(twoHoursAgo));
      _humidityHistory
          .removeWhere((point) => point.timestamp.isBefore(twoHoursAgo));

      // Generate temperature data
      final temp = _generateRandomValue(minTemp, maxTemp);
      final tempPoint = SensorDataPoint(
        timestamp: now,
        value: temp,
        isAlert: temp < minTemp || temp > maxTemp,
      );
      _temperatureHistory.add(tempPoint);

      if (!_temperatureController.isClosed) {
        _temperatureController
            .add(List<SensorDataPoint>.from(_temperatureHistory));
      }

      // Check temperature alerts
      if (tempPoint.isAlert) {
        await alertService.addAlert(
          AlertType.temperature,
          'Température anormale: ${temp.toStringAsFixed(1)}°C',
          _currentBatchId!,
        );
      }

      // Generate humidity data
      final humidity = _generateRandomValue(minHumidity, maxHumidity);
      final humidityPoint = SensorDataPoint(
        timestamp: now,
        value: humidity,
        isAlert: humidity < minHumidity || humidity > maxHumidity,
      );
      _humidityHistory.add(humidityPoint);

      if (!_humidityController.isClosed) {
        _humidityController.add(List<SensorDataPoint>.from(_humidityHistory));
      }

      // Check humidity alerts
      if (humidityPoint.isAlert) {
        await alertService.addAlert(
          AlertType.humidity,
          'Humidité anormale: ${humidity.toStringAsFixed(1)}%',
          _currentBatchId!,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error generating data point: $e\n$stackTrace');
      _handleError('Error generating data: $e');
    }
  }

  void _handleError(String error) {
    if (_isDisposed) return;
    if (!_temperatureController.isClosed) {
      _temperatureController.addError(error);
    }
    if (!_humidityController.isClosed) {
      _humidityController.addError(error);
    }
  }

  double _generateRandomValue(double min, double max) {
    final random = math.Random();
    // 80% chance of being within normal range
    if (random.nextDouble() > 0.2) {
      return min + (random.nextDouble() * (max - min));
    }
    // 20% chance of being slightly outside range
    final deviation = (max - min) * 0.1;
    return random.nextBool()
        ? min - (random.nextDouble() * deviation)
        : max + (random.nextDouble() * deviation);
  }

  void dispose() {
    debugPrint('Disposing SensorDataService');
    _isDisposed = true;
    _stopMonitoring();
    if (!_temperatureController.isClosed) {
      _temperatureController.close();
    }
    if (!_humidityController.isClosed) {
      _humidityController.close();
    }
  }
}
