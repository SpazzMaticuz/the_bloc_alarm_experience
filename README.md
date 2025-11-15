Alarm & Timer App (Flutter + BLoC Architecture)
Overview

This project is a multi-purpose alarm and timer application built with Flutter and Dart, designed primarily as a learning project to explore and practice the BLoC and Cubit architecture patterns.

It provides a unified interface for managing:

Alarms — with local notifications for waking up, sleeping, or reminders

Countdown timers — with optional lap tracking for measuring time intervals

Stopwatch functionality — to measure elapsed time precisely

The project was intentionally kept simple and modular, focusing on clean architecture, separation of concerns, and reactive state management using Flutter BLoC.

Tech Stack

Framework: Flutter

Language: Dart

Database: SQLite (via sqflite and path_provider)

Architecture: BLoC / Cubit pattern for state management

Packages Used
Package	Purpose
flutter_bloc / bloc	Core state management (BLoC + Cubit)
equatable	Simplified state comparison
stop_watch_timer	Stopwatch functionality with laps
flutter_time_picker_spinner	Custom time picker UI
awesome_notifications	Local notifications and alarm alerts
just_audio, audioplayers	Audio playback for alarms and timers
sqflite, path_provider	Local data persistence (SQLite database)
flutter_lints	Code style and linting rules
