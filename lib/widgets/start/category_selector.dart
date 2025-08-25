import 'package:flutter/material.dart';
import '../../utils/word_category.dart';

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
                      category.name,
                      style: TextStyle(
                        color: unlocked ? Colors.cyanAccent : Colors.redAccent,
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock,
                          size: 16, color: Colors.redAccent),
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