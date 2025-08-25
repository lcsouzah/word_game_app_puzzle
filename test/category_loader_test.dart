import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/services/category_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadCategories reads animals word list', () async {
    final categories = await loadCategories();
    final animals = categories.firstWhere((c) => c.name == 'Animals');
    expect(animals.allWords, isNotEmpty);
    expect(animals.allWords.first, 'Ant');
    expect(animals.allWords, contains('Cat'));
  });
}