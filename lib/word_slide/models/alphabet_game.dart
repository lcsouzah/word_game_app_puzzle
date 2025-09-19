import 'dart:math';

import 'package:flutter/cupertino.dart';

enum ScoringOption {
  horizontal,
  vertical,
  both,
}

class AlphabetGame {
  List<String> letters = [];
  final List<String> _originalWordList;
  final List<String> _usedWords = [];
  List<String> _availableWords = [];
  int emptyTileIndex = 0;

  AlphabetGame(List<String> wordList)
      : _originalWordList = List.from(wordList) {
    _availableWords = List.from(_originalWordList)..shuffle();
    letters = _generateRandomLetters();
  }

  List<String> _generateRandomLetters() {
    final Random random = Random();

    // Filter for words up to 15 characters and not already used
    List<String> suitableWords = _availableWords
        .where((word) => word.length <= 15 && !_usedWords.contains(word))
        .toList();

    if (suitableWords.isEmpty) {
      debugPrint("⚠️ No more unused suitable words found. Resetting...");
      resetWordPool();
      suitableWords = _availableWords
          .where((word) => word.length <= 15 && !_usedWords.contains(word))
          .toList();
    }

    String selectedWord = suitableWords[random.nextInt(suitableWords.length)].trim();
    _usedWords.add(selectedWord);
    _availableWords.remove(selectedWord);

    List<String> result = selectedWord.split('');
    while (result.length < 15) {
      result.add(selectedWord[random.nextInt(selectedWord.length)]);
    }

    result.shuffle();
    result.insert(0, ' '); // Insert blank tile
    emptyTileIndex = 0;

    debugPrint("📌 Selected word: $selectedWord");
    debugPrint("🧩 Generated letters: $result");

    return result;
  }

  void generateNewLetters() {
    letters = _generateRandomLetters();
  }

  void resetWordPool() {
    _usedWords.clear();
    _availableWords = List.from(_originalWordList)..shuffle();
  }

  bool moveTile(int index) {
    if (_isValidMove(index)) {
      letters[emptyTileIndex] = letters[index];
      letters[index] = ' ';
      emptyTileIndex = index;
      return true;
    }
    return false;
  }

  bool _isValidMove(int index) {
    if (letters[index] == letters[emptyTileIndex]) return false;

    int rowDiff = (index ~/ 4) - (emptyTileIndex ~/ 4);
    int colDiff = (index % 4) - (emptyTileIndex % 4);
    return (rowDiff == 1 && colDiff == 0) ||
        (rowDiff == -1 && colDiff == 0) ||
        (rowDiff == 0 && colDiff == 1) ||
        (rowDiff == 0 && colDiff == -1);
  }

  String getWordVertical() {
    const int gridSize = 4;
    String word = '';
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize; row++) {
        int index = row * gridSize + col;
        String letter = letters[index];
        if (letter == ' ') return word;
        word += letter;
      }
    }
    return word;
  }

  String getWord() {
    String word = '';
    for (String letter in letters) {
      if (letter == ' ') break;
      word += letter;
    }
    return word;
  }

  void clearWord() {
    for (int i = 0; i < letters.length; i++) {
      if (i != emptyTileIndex) {
        letters[i] = '';
      }
    }
  }
}
