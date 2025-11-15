import 'package:flutter/material.dart';

/// Observes app lifecycle (foreground/background) and notifies listeners
class AppLifecycleObserver extends ChangeNotifier with WidgetsBindingObserver {
  // Singleton instance
  static final AppLifecycleObserver _instance = AppLifecycleObserver._internal();
  factory AppLifecycleObserver() => _instance;

  AppLifecycleObserver._internal() {
    // Register observer to track lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  // Tracks whether the app is currently in foreground
  bool _isInForeground = true;
  bool get isInForeground => _isInForeground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update foreground status on lifecycle change
    _isInForeground = state == AppLifecycleState.resumed;
    notifyListeners(); // Notify subscribers of change
  }

  // Call to remove observer when no longer needed
  void disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
