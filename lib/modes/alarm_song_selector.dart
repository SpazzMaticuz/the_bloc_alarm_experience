import 'package:flutter/material.dart';

// --- SONG LIST ---
const List<String> availableAlarmSongs = [
  'songs/alarm.mp3',
  'songs/monkey.mp3',
  'songs/raid.mp3',
  'songs/runaway.mp3',
  'songs/time to say goodbye.mp3',
];

// Helper: Convert asset path to a friendly display name
String getSongNameFromPath(String path) {
  final fileName = path.split('/').last.replaceAll('.mp3', '');
  return fileName
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) =>
  word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Shows a bottom sheet to select an alarm sound.
/// Returns the selected song path or null if dismissed.
Future<String?> showAlarmSongSelector(
    BuildContext context,
    String? currentSelection,
    ) {
  // Default to 'alarm.mp3' if no selection exists
  final initialSelection = currentSelection?.isNotEmpty == true
      ? currentSelection!
      : 'songs/alarm.mp3';

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // Temporary selection while browsing
          String tempSelection = initialSelection;

          return Container(
            height: 400, // Fixed height
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Alarm Sound',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableAlarmSongs.length,
                    itemBuilder: (context, index) {
                      final songPath = availableAlarmSongs[index];
                      final songName = getSongNameFromPath(songPath);
                      final isSelected = songPath == tempSelection;

                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.music_note,
                          color: isSelected ? Colors.deepOrange : Colors.grey[700],
                        ),
                        title: Text(
                          songName,
                          style: TextStyle(
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          // Update selection and close bottom sheet
                          setModalState(() {
                            tempSelection = songPath;
                          });
                          Navigator.pop(context, songPath);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
