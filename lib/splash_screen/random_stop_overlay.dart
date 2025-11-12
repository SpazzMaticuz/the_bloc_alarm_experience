import 'dart:math';
import 'package:flutter/material.dart';

class RandomStopOverlay extends StatefulWidget {
  final VoidCallback onStopPressed;
  const RandomStopOverlay({super.key, required this.onStopPressed});

  @override
  State<RandomStopOverlay> createState() => _RandomStopOverlayState();
}

class _RandomStopOverlayState extends State<RandomStopOverlay> {
  double? _buttonTop;
  double? _buttonLeft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateRandomPosition();
  }

  void _generateRandomPosition() {
    final size = MediaQuery.of(context).size;
    const buttonWidth = 120.0;
    const buttonHeight = 60.0;

    final random = Random();

    // ensure button is fully inside screen bounds
    final left = random.nextDouble() * (size.width - buttonWidth);
    final top = random.nextDouble() * (size.height - buttonHeight - 100); // avoid status bar area

    setState(() {
      _buttonLeft = left;
      _buttonTop = top;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Find the STOP button!',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (_buttonTop != null && _buttonLeft != null)
            Positioned(
              top: _buttonTop,
              left: _buttonLeft,
              child: ElevatedButton(
                onPressed: () {
                  widget.onStopPressed();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('STOP', style: TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }
}
