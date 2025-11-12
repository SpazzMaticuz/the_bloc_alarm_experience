import 'package:flutter/material.dart';

class AppLifecycleObserver extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLifecycleObserver _instance = AppLifecycleObserver._internal();
  factory AppLifecycleObserver() => _instance;
  AppLifecycleObserver._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _isInForeground = true;
  bool get isInForeground => _isInForeground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    notifyListeners();
  }

  void disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}