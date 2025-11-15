import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main_menu/alarms.dart';
import 'main_menu/stopwatch.dart';
import 'main_menu/timers.dart';

class MainScreenHolder extends StatefulWidget {
  const MainScreenHolder({Key? key}) : super(key: key);

  @override
  State<MainScreenHolder> createState() => _MainScreenHolderState();
}

class _MainScreenHolderState extends State<MainScreenHolder> {
  int _currentIndex = 0;

  // Tab screens
  final List<Widget> _screens = [const Alarms(), const Stopwatch(), Timers()];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Keeps all screens alive and shows only the selected one
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarms'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm_on_rounded), label: 'Stopwatch'),
          BottomNavigationBarItem(icon: Icon(Icons.timer_sharp), label: 'Timers'),
        ],
      ),
    );
  }
}
