import 'package:flutter/material.dart';

// Circular button with text inside
class CircularTextButton extends StatelessWidget {
  final String text; // Text inside the button
  final VoidCallback onPressed; // Tap handler
  final double size; // Diameter of the circle
  final TextStyle? textStyle; // Optional text style
  final Color backgroundColor; // Button background color

  const CircularTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = 50.0,
    this.textStyle,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: const CircleBorder(), // Ensures circular shape
          backgroundColor: backgroundColor,
          padding: EdgeInsets.all(24), // Controls inner spacing
        ),
        child: Text(
          text,
          style: textStyle ?? const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
