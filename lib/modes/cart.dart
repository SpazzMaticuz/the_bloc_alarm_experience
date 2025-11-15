import 'package:flutter/material.dart';

/// A reusable AlarmCard widget that displays:
/// - Time (hour + AM/PM)
/// - A label and optional note
/// - A switch (on/off)
/// - Detects taps to open/edit alarm
///
/// All values are passed via constructor (e.g. from a database).
class AlarmCard extends StatelessWidget {
  final String time;          // e.g. "9:45"
  final String period;        // e.g. "AM" or "PM"
  final String label;         // e.g. "Take medicine"
  final String note;          // optional note
  final bool isActive;        // true/false for switch
  final ValueChanged<bool> onToggle; // called when switch changes
  final VoidCallback? onTap;  // ✅ called when user taps the card

  const AlarmCard({
    super.key,
    required this.time,
    required this.period,
    required this.label,
    this.note = "",
    required this.isActive,
    required this.onToggle,
    this.onTap, // optional tap callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Handle taps for editing
      onTap: onTap,

      // ✅ Long press can be used later for selection/multi-edit
      onLongPress: () {
        debugPrint("Long pressed: $label");
      },

      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔹 Left side: time and label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time + AM/PM
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Label + optional note
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // 🔹 Right side: switch
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeThumbColor: Colors.orangeAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
