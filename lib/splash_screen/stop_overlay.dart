import 'package:flutter/material.dart';

class StopOverlay extends StatelessWidget {
  final VoidCallback onStopPressed;
  const StopOverlay({super.key, required this.onStopPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Timer Finished!',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onStopPressed(); // stop sound
                Navigator.of(context).pop(); // close overlay
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('STOP', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
