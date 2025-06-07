//alphabet_game.dart


import 'dart:math';

enum ScoringOption {
  Horizontal,
  Vertical,
  Both,
}

class AlphabetGame {
  List<String> letters = [];
  final List<String> wordList;
  int emptyTileIndex = 0;

  AlphabetGame(this.wordList) {


    letters = _generateRandomLetters(wordList);

  }


  List<String> _generateRandomLetters(List<String> wordList) {
    Random random = Random();

    // Filter the word list to words that are 15 characters or less
    List<String> suitableWords = wordList.where((word) => word.length <= 15)
        .toList();
    if (suitableWords.isEmpty) {
      return List.filled(
          15, ' '); // Return a default list if no suitable words are found
    }

    // Select a random word from the suitable words
    String selectedWord = suitableWords[random.nextInt(suitableWords.length)]
        .trim();

    // Create a list of letters from the word, filling the rest with random letters from the word
    List<String> letters = selectedWord.split('')
      ..addAll(
          List.generate(
              15 - selectedWord.length, (_) => selectedWord[random.nextInt(
              selectedWord.length)])
      );

    // Shuffle and place the letters in the grid
    letters.shuffle();
    letters.insert(emptyTileIndex, ' '); // Insert the empty space

    return letters;
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
    if (letters[index] == letters[emptyTileIndex]) {
      return false;
    } else {
      int rowDiff = (index ~/ 4) - (emptyTileIndex ~/ 4);
      int colDiff = (index % 4) - (emptyTileIndex % 4);
      return (rowDiff == 1 && colDiff == 0) ||
          (rowDiff == -1 && colDiff == 0) ||
          (rowDiff == 0 && colDiff == 1) ||
          (rowDiff == 0 && colDiff == -1);
    }
  }



  String getWordVertical() {
    const int gridSize = 4; // Assuming a 4x4 grid
    String word = '';

    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize; row++) {
        int index = row * gridSize + col;
        String letter = letters[index];
        if (letter == ' ') {
          return word; // Return the word immediately when a blank tile is encountered
        }
        word += letter;
      }
    }
    return word; // Returns the word formed by traversing vertically through columns
  }



  String getWord() {
    String word = '';
    // Assuming letters is a flat list representing a 4x4 grid row-wise.
    for (String letter in letters) {
      if (letter == ' ') { // If a blank tile is encountered, stop adding letters.
        break;
      }
      word += letter; // Concatenate the letter to form a word.
    }
    return word;
  }


  void clearWord() {
    // Implement the logic to clear the tiles forming a word.
    // Reset the letters at the positions forming the word.
    for (int i = 0; i < letters.length; i++) {
      if (letters[i] != ' ') {
        letters[i] = ' ';
      }
    }
  }


  void generateNewLetters(List<String> wordList) {
    // Call _generateRandomLetters to refill the board
    letters = _generateRandomLetters(wordList);
    // Optionally, you can add additional logic here if needed
  }
}
