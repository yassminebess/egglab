import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class IncubationProgress extends StatelessWidget {
  final DateTime startDate;
  final int totalDays;
  static const double _twoPi = math.pi * 2;

  const IncubationProgress({
    super.key,
    required this.startDate,
    this.totalDays = 21,
  });

  int get _currentDay {
    final difference = DateTime.now().difference(startDate).inDays;
    return math.min(difference + 1, totalDays);
  }

  int get _daysRemaining {
    return math.max(0, totalDays - _currentDay);
  }

  double get _progressPercent {
    return _currentDay / totalDays;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor =
        HSLColor.fromColor(primaryColor).withLightness(0.7).toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            children: [
              // Background shadow
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Background circle
              CustomPaint(
                size: const Size(200, 200),
                painter: _ProgressArcPainter(
                  progressPercent: 1.0,
                  color: Colors.grey.withAlpha(30),
                  strokeWidth: 18,
                ),
              ),
              // Progress circle
              CustomPaint(
                size: const Size(200, 200),
                painter: _ProgressArcPainter(
                  progressPercent: _progressPercent,
                  color: accentColor,
                  strokeWidth: 18,
                  useGradient: true,
                  endColor: primaryColor,
                ),
              ),
              // Center text
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Jour',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentDay',
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          height: 0.9,
                        ),
                      ),
                    ),
                    Text(
                      'sur $totalDays',
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Days remaining label outside the circle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _daysRemaining > 0
                ? Colors.amber.withAlpha(40)
                : Colors.green.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _daysRemaining > 0
                ? '$_daysRemaining jours restants'
                : 'Éclosion !',
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _daysRemaining > 0
                    ? Colors.amber.shade900
                    : Colors.green.shade800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progressPercent;
  final Color color;
  final double strokeWidth;
  final bool useGradient;
  final Color? endColor;

  _ProgressArcPainter({
    required this.progressPercent,
    required this.color,
    this.strokeWidth = 10.0,
    this.useGradient = false,
    this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (useGradient && endColor != null) {
      paint.shader = SweepGradient(
        colors: [color, endColor!],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        tileMode: TileMode.repeated,
      ).createShader(rect);
    } else {
      paint.color = color;
    }

    // Start at top (negative y-axis)
    const startAngle = -math.pi / 2;
    final sweepAngle = IncubationProgress._twoPi * progressPercent;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progressPercent != progressPercent ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useGradient != useGradient ||
        oldDelegate.endColor != endColor;
  }
}
