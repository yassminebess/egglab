import '../models/sensor_data.dart';

class SensorService {
  // This is a mock service that returns dummy data
  // Replace with actual sensor integration later
  Future<List<SensorData>> getLast24HoursData(String batchId) async {
    // Return empty list for now
    return [];
  }

  void dispose() {
    // Clean up resources if needed
  }

  List<SensorData> getTemperatureData(int days) {
    return MockDataGenerator.generateTemperatureData(days);
  }

  List<SensorData> getHumidityData(int days) {
    return MockDataGenerator.generateHumidityData(days);
  }
}
