//Y:\word_game_app_puzzle\lib\screens\game_screen.dart


import 'package:flutter/material.dart';
import '../widget/tap_feedback_overlay.dart'; //
import '../models/alphabet_game.dart';
import '../widget/tile.dart';
import '../utils/sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/safe_area.dart';


class GameScreen extends StatefulWidget {
  final Function(String) onCorrectWord;
  final AlphabetGame game;
  final List<String> dictionary;
  final ScoringOption scoringOption;
  final VoidCallback onPauseToggle;

  const GameScreen({super.key,
    required this.game,
    required this.dictionary,
    required this.onCorrectWord,
    required this.scoringOption,
    required this.onPauseToggle,
  });

  @override

  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {

  bool _showTutorial = false;

  int _hintsUsed = 0;
  final int _maxHints = 3;


  int moveCounter = 0;// Add this line to initialize the move counter
  List<int> _highlightedIndices = [];




  String? _findClosestWord(List<String> boardLetters) {
    int bestScore = 0;
    String? bestMatch;

    for (final word in widget.dictionary) {
      int score = 0;
      for (int i = 0; i < word.length && i < boardLetters.length; i++) {
        if (word[i] == boardLetters[i]) {
          score++;
        } else {
          break; // Stop on first mismatch for prefix match
        }
      }

      if (score > bestScore && score >= 2) {
        bestScore = score;
        bestMatch = word;
      }
    }

    return bestMatch;
  }


  void _showHint() async {

    if(_hintsUsed >= _maxHints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have used all your hits.")),
      );
      return;

    }

    List<String> boardLetters = [];
    for (var letter in widget.game.letters) {
      if (letter != ' ') boardLetters.add(letter);
    }

    String? hintWord = _findClosestWord(boardLetters);

    if (hintWord != null) {
      _hintsUsed++;

      final indices = _findMatchingIndices(hintWord);

      setState(() {
        _highlightedIndices = indices;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _highlightedIndices.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No obvious hints available right now.")),
      );
    }
  }


  //late SoundManager soundManager = SoundManager();

  List<int> _findMatchingIndices(String word) {
    List<int> indices = [];
    final tiles = widget.game.letters;
    int matchIndex = 0;

    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] == word[matchIndex]) {
        indices.add(i);
        matchIndex++;
        if (matchIndex >= word.length) break;
      }
    }

    return indices;
  }



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
        print('🎉 Matched word: $word');

        // Highlight tiles that form the word
        setState(() {
          _highlightedIndices = _findMatchingIndices(word);
        });

        // Wait before clearing
        await Future.delayed(const Duration(milliseconds: 600));


        setState(() {
          _highlightedIndices.clear();
          widget.game.clearWord();
          widget.game.generateNewLetters();
        });

        return;
      }
    }

    // If no word is formed correctly, optionally handle this scenario
    print('The formed word is not correct.$formedWords' );
    setState(() {}); // Ensure to refresh the UI if needed
  }




  @override

  void initState() {
    super.initState();
    _loadTutorialStatus();
}

Future<void> _loadTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seenTutorial = prefs.getBool('seen_tutorial') ?? false;

    if(!seenTutorial){
      setState(() {
        _showTutorial = true;
      });
      prefs.setBool('seen_tutorial', true);
    }
}

void _showPauseMenu(){
    showDialog(
    context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pause'),
            content: const Text('What would you like to do?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); //Resume
                },
                child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showTutorial = true; //replay tutorial
              });
            },
            child: const Text('Replay Tutorial'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); //Exit game
            },
            child: const Text('Exit Game'),
          )]

          );
        }

    );
}

  Widget build(BuildContext context) {
    return TouchFeedbackOverlay(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _showHint,
            label: Text('Hint (${_maxHints - _hintsUsed})'),
            icon: const Icon(Icons.lightbulb_outline),
            backgroundColor: _hintsUsed < _maxHints ? Colors.amber : Colors.grey,
        ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,


      appBar: AppBar(
        centerTitle: true,
        title: Text('Moves: $moveCounter'),
        actions:[
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () {
                widget.onPauseToggle();
                _showPauseMenu();
                },
          ),// Display move counter here
        ],
      ),


              body: Stack(
              children: [
              //Game board
              GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
              final letter = widget.game.letters[index];
              return TileWidget(
              letter: letter,
              onTap: () => _handleTileTap(index),
              highlighted: _highlightedIndices.contains(index),
              );
              },
              ),
              //Tutorial Overlay
              if(_showTutorial)
              Positioned.fill(
              child: Container(
              color: Colors.black.withOpacity(0.75),
              child: Stack(
              children: [
              //Fading hand Animation
              Positioned(
              left: MediaQuery.of
                (context).size.width * 0.25,
                top: MediaQuery.of(context).size.height * 0.65,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity : 1 - value,
                      child: Transform.translate(
                        offset: Offset(value * 40, -value * 40),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/hand_pointer.gif',
                    width: 64,
                    height: 64,

                  ),
                  onEnd: () {
                    if(_showTutorial) setState((){}); // loop animation
                  },
                ),
              ),



        // Text + button column
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "👆 Tap and slide tiles",
                style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              const SizedBox(height: 20),
              const Text(
                "🧠 Form real English words",
                style: TextStyle(color: Colors.white60, fontSize: 18),
                ),
              const SizedBox(height: 20),
              const Text(
                '💡 Use the hint button when stuck',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 18),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed:() {
                  setState((){
                    _showTutorial = false;
                });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text ("Got it, LET'S GO!"),
              )
            ],
          ),
        ),
      ],
          ),
    ),
    ),
    ]
    ))
    );
  }
}
