import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final int selectedTime;
  final ValueChanged<int?> onChanged;

  const TimeSelector({
    super.key,
    required this.selectedTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      iconSize: 24,
      value: selectedTime,
      dropdownColor: Colors.black,
      iconEnabledColor: Colors.orange,
      style: const TextStyle(color: Colors.orangeAccent),
      underline: Container(height: 3, width: 3, color: Colors.orange),
      onChanged: onChanged,
      items: const [
        DropdownMenuItem<int>(
          value: 60,
          child: Text(
            '1 Minute',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 32,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        DropdownMenuItem<int>(
          value: 120,
          child: Text(
            '2 Minutes',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 32,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        DropdownMenuItem<int>(
          value: 180,
          child: Text(
            '3 Minutes',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 32,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}