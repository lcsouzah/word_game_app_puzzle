import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/services/category_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadCategories loads all categories', () async {
    final categories = await loadCategories();
    expect(categories, hasLength(11));

    final names = categories.map((c) => c.name).toList();
    expect(
      names,
      containsAll([
        'Dictionary',
        'Food',
        'Animals',
        'Fruits',
        'Body Parts',
        'Clothing',
        'Colors',
        'Countries',
        'Jobs',
        'Transportation',
        'Weather',
      ]),
    );

    for (final category in categories) {
      expect(category.allWords, isNotEmpty, reason: '${category.name} should have words');
    }
  });

  test('loadWordList returns empty list for missing asset', () async {
    final words = await loadWordList('assets/missing/words.txt');
    expect(words, isEmpty);
  });
}