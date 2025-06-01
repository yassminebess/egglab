import 'package:flutter/material.dart';

class CustomTimelineTile extends StatelessWidget {
  final String title;
  final DateTime date;
  final int currentDay;
  final int totalDays;
  final bool isCompleted;
  final bool isLast;
  final String? subtitle;

  const CustomTimelineTile({
    super.key,
    required this.title,
    required this.date,
    required this.currentDay,
    required this.totalDays,
    this.isCompleted = false,
    this.isLast = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left column (subtitle above, then circle)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      width: 80,
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFFC107), // yellow accent
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.amber : Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "$currentDay/$totalDays",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.amber,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Right column (title and date/time only, vertically stacked, slightly lower)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8), // Push title down a bit
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} – ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
