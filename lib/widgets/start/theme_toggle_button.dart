import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final VoidCallback onToggle;
  const ThemeToggleButton({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: const Icon(Icons.brightness_6, color: Colors.white),
    );
  }
}