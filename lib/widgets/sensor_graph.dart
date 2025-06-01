import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sensor_data_service.dart';

class SensorGraph extends StatefulWidget {
  final List<SensorDataPoint> dataPoints;
  final String title;
  final String unit;
  final double minThreshold;
  final double maxThreshold;
  final Color normalColor;
  final Color alertColor;

  const SensorGraph({
    super.key,
    required this.dataPoints,
    required this.title,
    required this.unit,
    required this.minThreshold,
    required this.maxThreshold,
    required this.normalColor,
    required this.alertColor,
  });

  @override
  State<SensorGraph> createState() => _SensorGraphState();
}

class _SensorGraphState extends State<SensorGraph> {
  bool _showFullHistory = false;

  List<SensorDataPoint> get _visiblePoints {
    if (!_showFullHistory) {
      // Show last 2 hours of data
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      return widget.dataPoints
          .where((point) => point.timestamp.isAfter(twoHoursAgo))
          .toList();
    }
    return widget.dataPoints;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullHistory = !_showFullHistory;
        });
      },
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              widget.normalColor.withAlpha(10),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _showFullHistory ? "Vue complète" : "Dernières 2 heures",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval:
                        (widget.maxThreshold - widget.minThreshold) / 4,
                    verticalInterval: 30,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval:
                            (widget.maxThreshold - widget.minThreshold) / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toStringAsFixed(1)}${widget.unit}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 30, // Show time every 30 minutes
                        getTitlesWidget: (value, meta) {
                          if (_visiblePoints.isEmpty) return const Text('');

                          final index = value.toInt();
                          if (index >= 0 && index < _visiblePoints.length) {
                            final point = _visiblePoints[index];
                            // Only show time for every 30 minutes
                            if (point.timestamp.minute % 30 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${point.timestamp.hour.toString().padLeft(2, '0')}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                          }
                          return const Text('');
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
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (_visiblePoints.length - 1).toDouble(),
                  minY: widget.minThreshold -
                      ((widget.maxThreshold - widget.minThreshold) * 0.2),
                  maxY: widget.maxThreshold +
                      ((widget.maxThreshold - widget.minThreshold) * 0.2),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _visiblePoints.asMap().entries.map((entry) {
                        final value = entry.value.value;
                        return FlSpot(
                          entry.key.toDouble(),
                          value,
                        );
                      }).toList(),
                      isCurved: true,
                      color: widget.normalColor,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final value = _visiblePoints[index].value;
                          final color = (value < widget.minThreshold ||
                                  value > widget.maxThreshold)
                              ? widget.alertColor
                              : widget.normalColor;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: widget.minThreshold,
                        color: Colors.red.withAlpha(77),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                      HorizontalLine(
                        y: widget.maxThreshold,
                        color: Colors.red.withAlpha(77),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
