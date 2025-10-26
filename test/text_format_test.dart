import 'package:flutter_test/flutter_test.dart';
import 'package:word_game_app/utils/text_format.dart';

void main() {
  group('titleCaseFirstOnly', () {
    test('capitalizes only first alphabetical character', () {
      expect(titleCaseFirstOnly('example'), 'Example');
    });

    test('lowercases remaining characters', () {
      expect(titleCaseFirstOnly('hELLO'), 'Hello');
    });

    test('skips leading whitespace', () {
      expect(titleCaseFirstOnly('  spaced'), '  Spaced');
    });

    test('leaves empty string untouched', () {
      expect(titleCaseFirstOnly(''), '');
    });

    test('non alphabetic prefix preserved', () {
      expect(titleCaseFirstOnly('#hashTag'), '#Hashtag');
    });
  });
}