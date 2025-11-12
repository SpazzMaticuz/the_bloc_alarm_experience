// --- Utility functions for conversion in your application logic ---

/// Converts an hour/minute combination to the integer used in the database.
int timeToMinutesSinceMidnight(int hour, int minute) {
  // hour must be 0-23, minute must be 0-59
  return (hour * 60) + minute;
}

/// Converts the database integer back to separate hour and minute.
Map<String, int> minutesSinceMidnightToTime(int totalMinutes) {
  // Hour is the result of integer division
  int hour = totalMinutes ~/ 60;
  // Minute is the remainder
  int minute = totalMinutes % 60;

  return {
    'hour': hour,
    'minute': minute,
  };
}

// --- Example Usage ---

// To SAVE (e.g., alarm is set for 7:30 AM)
int minutesToSave = timeToMinutesSinceMidnight(7, 30); // minutesToSave is 450

Map<String, dynamic> newAlarm = {
  'minutesSinceMidnight': minutesToSave,
  'isActive': 1,
  // ... other fields
};

// To READ (e.g., retrieving the value 450)
int retrievedMinutes = 450;
Map<String, int> time = minutesSinceMidnightToTime(retrievedMinutes); // time is {'hour': 7, 'minute': 30}