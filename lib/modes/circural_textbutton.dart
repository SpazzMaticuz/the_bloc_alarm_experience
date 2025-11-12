import 'package:flutter/material.dart';

class CircularTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double size;
  final TextStyle? textStyle;
  final Color backgroundColor;

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
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: backgroundColor,
          padding: EdgeInsets.all(24),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: textStyle ?? const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
