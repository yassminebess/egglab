import 'dart:math';
import 'package:flutter/material.dart';

class IncubationProgressCircle extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const IncubationProgressCircle({
    super.key,
    required this.currentDay,
    this.totalDays = 21,
    this.size = 200,
    this.primaryColor = const Color(0xFF4CAF50),
    this.secondaryColor = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressCirclePainter(
              progress: currentDay / totalDays,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Jour $currentDay',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'sur $totalDays',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _ProgressCirclePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const startAngle = -pi / 2;

    // Draw background circles
    final bgPaint = Paint()
      ..color = Colors.grey.withAlpha(51)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0;

    canvas.drawCircle(center, radius - 20, bgPaint);
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress on outer circle
    final outerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi * progress,
      false,
      outerPaint,
    );

    // Draw progress on inner circle
    final innerPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      startAngle,
      2 * pi * progress,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
