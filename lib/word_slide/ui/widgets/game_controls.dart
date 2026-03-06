import 'package:flutter/material.dart';
import 'package:word_game_app/utils/text_format.dart';
import 'package:word_game_app/utils/word_category.dart';
import 'package:word_game_app/word_slide/core/game_config.dart';

class StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const StartButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        splashColor: Colors.orangeAccent.withValues(alpha: 0.5),
        highlightColor: Colors.orangeAccent.withValues(alpha: 0.2),
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class LeaderboardButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const LeaderboardButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        splashColor: Colors.purpleAccent.withValues(alpha: 0.5),
        highlightColor: Colors.purpleAccent.withValues(alpha: 0.2),
        onTap: () {
          onTap();
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<WordCategory> categories;
  final String? selectedCategory;
  final Future<bool> Function(String category) isCategoryUnlocked;
  final Future<bool> Function(String category) promptUnlock;
  final ValueChanged<String> onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.isCategoryUnlocked,
    required this.promptUnlock,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButton<String>(
        value: selectedCategory,
        hint: const SizedBox.shrink(),
        iconSize: 30,
        isExpanded: true,
        dropdownColor: Colors.transparent.withValues(alpha: 0.8),
        underline: const SizedBox(),
        iconEnabledColor: Colors.cyanAccent,
        icon: const Icon(Icons.arrow_drop_down),
        selectedItemBuilder: (context) =>
            categories.map((_) => const SizedBox.shrink()).toList(),
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (String? newValue) async {
          if (newValue == null) return;
          if (await isCategoryUnlocked(newValue)) {
            onCategoryChanged(newValue);
          } else {
            final unlocked = await promptUnlock(newValue);
            if (unlocked) {
              onCategoryChanged(newValue);
            }
          }
        },
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category.name,
            child: FutureBuilder<bool>(
              future: isCategoryUnlocked(category.name),
              builder: (context, snapshot) {
                final unlocked = snapshot.data ?? false;
                return Row(
                  children: [
                    Text(
                      titleCaseFirstOnly(category.name),
                      style: TextStyle(
                        color: unlocked ? Colors.cyanAccent : Colors.redAccent,
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock, size: 16, color: Colors.redAccent),
                  ],
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

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
          label: Text(titleCaseFirstOnly(level.name)),
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