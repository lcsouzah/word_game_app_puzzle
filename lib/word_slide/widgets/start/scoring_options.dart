import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/alphabet_game.dart';
import 'package:word_game_app/utils/text_format.dart';


class ScoringOptions extends StatelessWidget {
  final ScoringOption groupValue;
  final ValueChanged<ScoringOption?> onChanged;

  const ScoringOptions({
    super.key,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ScoringOption>(
      options: ScoringOption.values,
      groupValue: groupValue,
      onChanged: onChanged,
      labelBuilder: (option) => Text(titleCaseFirstOnly(option.name)),
    );
  }
}

typedef RadioLabelBuilder<T> = Widget Function(T value);

class RadioGroup<T> extends StatelessWidget {
  final List<T> options;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final RadioLabelBuilder<T> labelBuilder;

  const RadioGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options
          .map(
            (option) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<T>(
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            labelBuilder(option),
          ],
        ),
      )
          .toList(),
    );
  }
}