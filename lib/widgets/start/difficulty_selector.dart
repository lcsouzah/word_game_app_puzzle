import 'package:flutter/material.dart';
import '../../models/difficulty_level.dart';

class DifficultySelector extends StatelessWidget {
  final DifficultyLevel selectedDifficulty;
  final ValueChanged<DifficultyLevel> onSelected;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: DifficultyLevel.values.map((level) {
        return ChoiceChip(
          backgroundColor: Colors.deepPurple.shade400,
          shadowColor: Colors.red,
          selectedColor: Colors.deepPurple.shade300,
          selectedShadowColor: Colors.greenAccent,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          elevation: 15,
          labelPadding: const EdgeInsets.all(5),
          label: Text(level.name),
          selected: selectedDifficulty == level,
          onSelected: (isSelected) {
            if (isSelected) {
              onSelected(level);
            }
          },
        );
      }).toList(),
    );
  }
}