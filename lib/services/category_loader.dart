import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../utils/word_category.dart';

Future<List<String>> loadWordList(String path) async {
  try {
    final content = await rootBundle.loadString(path);
    return content
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  } catch (e) {
    debugPrint('Failed to load $path: $e');
    return [];
  }
}

Future<List<WordCategory>> loadCategories() async {
  final categories = <WordCategory>[];

  const definitions = [
    {'name': 'Dictionary', 'path': 'assets/dictionary/words.txt'},
    {'name': 'Food', 'path': 'assets/food/words.txt'},
    {'name': 'Animals', 'path': 'assets/animals/words.txt'},
    {'name': 'Fruits', 'path': 'assets/fruits/words.txt'},
    {'name': 'Body Parts', 'path': 'assets/bodyparts/words.txt'},
    {'name': 'Clothing', 'path': 'assets/clothing/words.txt'},
    {'name': 'Colors', 'path': 'assets/colors/words.txt'},
    {'name': 'Countries', 'path': 'assets/countries/words.txt'},
    {'name': 'Jobs', 'path': 'assets/jobs/words.txt'},
    {'name': 'Transportation', 'path': 'assets/transportation/words.txt'},
    {'name': 'Weather', 'path': 'assets/weather/words.txt'},
  ];

  for (final def in definitions) {
    try {
      final words = await loadWordList(def['path']!);
      categories.add(WordCategory(name: def['name']!, allWords: words));
    } catch (e) {
      debugPrint('Failed to load category ${def['name']}: $e');
    }
  }

  return categories;
}