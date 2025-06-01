import 'dart:math';

class SensorData {
  final DateTime timestamp;
  final double value;

  SensorData(this.timestamp, this.value);
}

class MockDataGenerator {
  static List<SensorData> generateTemperatureData(int days) {
    final random = Random();
    final List<SensorData> data = [];
    final now = DateTime.now();

    // Generate data points every 5 minutes
    for (int i = days * 24 * 12; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 5));
      // Temperature fluctuates around 37.5°C (ideal incubation temperature)
      const baseTemp = 37.5;
      final variation = (random.nextDouble() - 0.5) * 0.6; // ±0.3°C variation
      data.add(SensorData(timestamp, baseTemp + variation));
    }
    return data;
  }

  static List<SensorData> generateHumidityData(int days) {
    final random = Random();
    final List<SensorData> data = [];
    final now = DateTime.now();

    // Generate data points every 5 minutes
    for (int i = days * 24 * 12; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 5));
      // Humidity fluctuates around 55% (ideal incubation humidity)
      const baseHumidity = 55.0;
      final variation = (random.nextDouble() - 0.5) * 6; // ±3% variation
      data.add(SensorData(timestamp, baseHumidity + variation));
    }
    return data;
  }
}
