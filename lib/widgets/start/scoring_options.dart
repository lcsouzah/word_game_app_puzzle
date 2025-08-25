import 'package:flutter/material.dart';
import '../../models/alphabet_game.dart'; // for ScoringOption

class ScoringOptions extends StatelessWidget {
  final ScoringOption groupValue;
  final ValueChanged<ScoringOption?> onChanged;

  const ScoringOptions({
    super.key,
    required this.groupValue,
    required this.onChanged,
  });

  Widget _buildOption(ScoringOption option) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<ScoringOption>(
          value: option,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(option.name),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ScoringOption.values.map(_buildOption).toList(),
    );
  }
}