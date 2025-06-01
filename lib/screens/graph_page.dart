import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late List<SensorData> temperatureData;
  late List<SensorData> humidityData;
  int selectedDays = 7; // Default to show 7 days of data

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  void _updateData() {
    temperatureData = MockDataGenerator.generateTemperatureData(selectedDays);
    humidityData = MockDataGenerator.generateHumidityData(selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphiques'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (days) {
              setState(() {
                selectedDays = days;
                _updateData();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('1 jour')),
              const PopupMenuItem(value: 7, child: Text('7 jours')),
              const PopupMenuItem(value: 14, child: Text('14 jours')),
              const PopupMenuItem(value: 21, child: Text('21 jours')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 4),
                  Text('Période'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGraphCard(
              'Température',
              temperatureData,
              Colors.red,
              '°C',
              37.2,
              37.8,
            ),
            const SizedBox(height: 16),
            _buildGraphCard('Humidité', humidityData, Colors.blue, '%', 52, 58),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphCard(
    String title,
    List<SensorData> data,
    Color color,
    String unit,
    double minLimit,
    double maxLimit,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minLimit - 2,
                    maxY: maxLimit + 2,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}$unit\n',
                              const TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: data[spot.x.toInt()]
                                      .timestamp
                                      .toString()
                                      .substring(11, 16),
                                  style: TextStyle(
                                    color: color.withAlpha(128),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: data.length / 6,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[value.toInt()]
                                    .timestamp
                                    .toString()
                                    .substring(11, 16),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      // Main data line
                      LineChartBarData(
                        spots: List.generate(
                          data.length,
                          (index) =>
                              FlSpot(index.toDouble(), data[index].value),
                        ),
                        isCurved: true,
                        color: color.withAlpha(128),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      // Upper limit line
                      LineChartBarData(
                        spots: [
                          FlSpot(0, maxLimit),
                          FlSpot(data.length.toDouble(), maxLimit),
                        ],
                        color: Colors.red.withAlpha(77),
                        barWidth: 1,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                      // Lower limit line
                      LineChartBarData(
                        spots: [
                          FlSpot(0, minLimit),
                          FlSpot(data.length.toDouble(), minLimit),
                        ],
                        color: Colors.red.withAlpha(77),
                        barWidth: 1,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
