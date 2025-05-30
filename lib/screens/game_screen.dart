import 'package:flutter/material.dart';

import '../models/alphabet_game.dart';
import '../widget/tile.dart';
import '../utils/sound_manager.dart';


class GameScreen extends StatefulWidget {
  final Function(String) onCorrectWord;
  final AlphabetGame game;
  final List<String> dictionary;
  final ScoringOption scoringOption;

  const GameScreen({super.key, required this.game, required this.dictionary,
    required this.onCorrectWord, required this.scoringOption});

  @override

  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int moveCounter = 0; // Add this line to initialize the move counter
  //late SoundManager soundManager = SoundManager();

  void _handleTileTap(int index) {
    if(widget.game.moveTile(index)){
       SoundManager.playSound('tileMove');
       moveCounter++; // Increment the move counter
       setState(() {});
    }
    _checkWord();
      setState(() {});
  }

  void _checkWord() async {
    // Initialize a variable to hold the formed word(s)
    List<String> formedWords = [];

    // Check based on the selected scoring option
    switch (widget.scoringOption) {
      case ScoringOption.Horizontal:
      // Assuming getWord() returns a list of horizontally formed words
        formedWords.add(widget.game.getWord()); // Adjusted to hypothetical method
        break;
      case ScoringOption.Vertical:
      // For vertical, we're already clear on getWordVertical()
        formedWords.add(widget.game.getWordVertical()); // Assuming it returns a single vertical word
        break;
      case ScoringOption.Both:
      // Combine both horizontal and vertical checks
        formedWords.add(widget.game.getWord()); // Adjusted to hypothetical method
        formedWords.add(widget.game.getWordVertical());
        break;
    }

    // Iterate through all formed words and check if any is correct
    for (String word in formedWords) {
      if (widget.dictionary.contains(word)) {
        widget.onCorrectWord(word);
        print('Congratulations! You formed a word: $word');
        widget.game.clearWord();
        widget.game.generateNewLetters(widget.dictionary);
        setState(() {}); // Refresh the UI
        return; // Exit after finding a correct word
      }
    }

    // If no word is formed correctly, optionally handle this scenario
    print('The formed word is not correct.$formedWords' );
    setState(() {}); // Ensure to refresh the UI if needed
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Word Game - Moves: $moveCounter'), // Display move counter here
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          final letter = widget.game.letters[index];
          return TileWidget(
            letter: letter,
            onTap: () => _handleTileTap(index),
          );
        },
      ),
    );
  }
}