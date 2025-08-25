//Y:\word_game_app_puzzle\lib\screens\game_screen.dart


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/tap_feedback_overlay.dart'; // need improvement
import '../models/alphabet_game.dart';
import '../widgets/tile.dart';
import '../utils/sound_manager.dart';
import '../utils/pause_manager.dart';


class GameScreen extends StatefulWidget {
  final Function(String) onCorrectWord;
  final AlphabetGame game;
  final List<String> dictionary;
  final ScoringOption scoringOption;
  final VoidCallback onPauseToggle;
  final void Function() onRewardedAdRequest;
  final int maxHints;
  final int adUsesThisMatch;
  final int maxAdUsesPerMatch;


  const GameScreen({
    super.key,
    required this.game,
    required this.dictionary,
    required this.onCorrectWord,
    required this.scoringOption,
    required this.onPauseToggle,
    required this.onRewardedAdRequest,
    required this.maxHints,
    required this.adUsesThisMatch,
    required this.maxAdUsesPerMatch,

  });

  @override

  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {


  late AnimationController _hintButtonController;
  late Animation<double> _hintButtonAnimation;



  late int _hintsUsed ;
  late int _maxHints;

  int moveCounter = 0;// Add this line to initialize the move counter
  List<int> _highlightedIndices = [];
  final List<int> _disappearingIndices = [];


  @override

  void initState() {
    super.initState();
    _maxHints =  widget.maxHints;
    _hintsUsed = 0;

    _hintButtonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _hintButtonAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _hintButtonController, curve: Curves.easeInOut));
  }


  @override
  void dispose() {
    _hintButtonController.dispose();
    super.dispose();
  }


  void addHints(int amount) {
    setState(() {
      _maxHints += amount;

      // If user had used all hints, reset hintsUsed to allow usage again
      if (_hintsUsed >= _maxHints) {
        _hintsUsed = _maxHints - amount;
      }

      // Ensure hintsUsed is never negative
      _hintsUsed = _hintsUsed.clamp(0, _maxHints);
      debugPrint('🧠 addHints called: maxHints=$_maxHints | hintsUsed=$_hintsUsed');
    });
  }

  void _handleTileTap(int index) {
    final pauseManager = Provider.of<PauseManager>(context, listen: false);

    // block movement if paused
    if (pauseManager.isPaused && pauseManager.pauseReason == PauseReason.manual) {
      return;
    }

    //auto resume if not manual pause
    if (pauseManager.isPaused && pauseManager.pauseReason != PauseReason.manual) {
      pauseManager.forceResume();
    }

    if(widget.game.moveTile(index)){
      SoundManager.playSound('tileMove');
      moveCounter++; // Increment the move counter
      setState(() {});
    }
    _checkWord();
  }

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

  /// Returns the tile indices that form [word].
  ///
  /// When [vertical] is `true`, tiles are checked column-by-column rather than
  /// left-to-right. This mirrors the order used by [AlphabetGame.getWord] and
  /// [AlphabetGame.getWordVertical] so that the indices line up with the solved
  /// word regardless of orientation.
  List<int> _findMatchingIndices(String word, {bool vertical = false}) {
    final List<int> indices = [];
    final tiles = widget.game.letters;
    int matchIndex = 0;

    const int gridSize = 4; // 4x4 grid

    if (vertical) {
      // Scan column-by-column, top-to-bottom
      for (int col = 0; col < gridSize && matchIndex < word.length; col++) {
        for (int row = 0; row < gridSize && matchIndex < word.length; row++) {
          final int i = row * gridSize + col;
          if (tiles[i] == ' ') {
            return indices; // stop at first blank tile
          }
          if (tiles[i] == word[matchIndex]) {
            indices.add(i);
            matchIndex++;
          }
        }
      }
    } else {
      // Default: scan left-to-right
      for (int i = 0; i < tiles.length && matchIndex < word.length; i++) {
        if (tiles[i] == ' ') {
          break; // stop at first blank tile
        }
        if (tiles[i] == word[matchIndex]) {
          indices.add(i);
          matchIndex++;
        }
      }
    }

    return indices;
  }

  void _showHint() async {
   // final pauseManager = Provider.of<PauseManager>(context, listen: false);

    debugPrint('💡 Requesting hint → hintsUsed: $_hintsUsed | maxHints: $_maxHints');

    if (_hintsUsed >= _maxHints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have used all your hints.")),
      );
      return;
    }

    //pauseManager.pause(PauseReason.hint);

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
    //pauseManager.resume(PauseReason.hint);
  }

  void _checkWord() async {
    // Collect formed words along with their orientation
    final List<Map<String, dynamic>> formedWords = [];

    switch (widget.scoringOption) {
      case ScoringOption.horizontal:
        formedWords.add({
          'word': widget.game.getWord(),
          'vertical': false,
        });
        break;
      case ScoringOption.vertical:
        formedWords.add({
          'word': widget.game.getWordVertical(),
          'vertical': true,
        });
        break;
      case ScoringOption.both:
        formedWords.add({
          'word': widget.game.getWord(),
          'vertical': false,
        });
        formedWords.add({
          'word': widget.game.getWordVertical(),
          'vertical': true,
        });
        break;
    }

    // Iterate through all formed words and check if any is correct
    for (final entry in formedWords) {
      final String word = entry['word'];
      final bool vertical = entry['vertical'];

      if (widget.dictionary.contains(word)) {
        widget.onCorrectWord(word);
        debugPrint('🎉 Matched word: $word');

        final indices = _findMatchingIndices(word, vertical: vertical);

        // ✅ Sequentially highlight each tile
        for (int i = 0; i < indices.length; i++) {
          await Future.delayed(Duration(milliseconds: 120 * i), () {
            if (!mounted) return;
            setState(() {
              _highlightedIndices.add(indices[i]);
            });
          });
        }

        // ✅ Keep them green for a moment
        await Future.delayed(const Duration(milliseconds: 50));

        // ✅ Sequentially "disappear" (shrink them one by one)
        for (int i = 0; i < indices.length; i++) {
          await Future.delayed(Duration(milliseconds: 50 * i), () {
            if (!mounted) return;
            setState(() {
              // replace highlight with disappearing animation
              _highlightedIndices.remove(indices[i]);
              _disappearingIndices.add(indices[i]);
            });
          });
        }

        // ✅ After all done → clear word & generate new letters
        await Future.delayed(const Duration(milliseconds: 50));

        setState(() {
          _disappearingIndices.clear();
          widget.game.clearWord();
          widget.game.generateNewLetters();
        });

        return;
      }
    }

    // If no word is formed correctly, optionally handle this scenario
    debugPrint('The formed word is not correct.$formedWords' );
    setState(() {}); // Ensure to refresh the UI if needed
  }


  @override
  Widget build(BuildContext context) {
    final pauseManager = Provider.of<PauseManager>(context);

    debugPrint('💡 BUILD → hintsUsed=$_hintsUsed | maxHints=$_maxHints');
    debugPrint('📺 Ads → adUsesThisMatch=${widget.adUsesThisMatch} | maxAdUsesPerMatch=${widget.maxAdUsesPerMatch}');

    // Decide button label & icon dynamically
    String label ;
    Icon icon;

    final canUseHint =  _hintsUsed < _maxHints;
    final canUseAd = widget.adUsesThisMatch < widget.maxAdUsesPerMatch;

    if (canUseHint) {
      label = 'Hint (${_maxHints - _hintsUsed})';
      icon = const Icon(Icons.lightbulb_outline);
    } else if (canUseAd) {
      label = 'Get +3 Hints';
      icon = const Icon(Icons.video_library);
    } else {
      label = 'No more hints';
      icon = const Icon(Icons.block);
    }

    return TouchFeedbackOverlay(
        child: Scaffold(
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: canUseHint
                      ? _hintButtonAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: FloatingActionButton.extended(
                    onPressed: (!canUseHint && !canUseAd)
                        ? null
                        : () {
                      if (canUseHint) {
                        _showHint();
                      } else {
                        widget.onRewardedAdRequest();
                        setState(() {});
                      }
                    },
                    label: Text(label),
                    icon: icon,
                    backgroundColor:
                    _hintsUsed < _maxHints ? Colors.amber : Colors.grey,
                  ),

                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,


            appBar: AppBar(
              centerTitle: true,
              title: Text('Moves: $moveCounter'),
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


                      return IgnorePointer(
                        ignoring: pauseManager.isPaused,
                        child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: TileWidget(
                          key:ValueKey(letter + index.toString()),
                          letter: letter,
                          onTap: () => _handleTileTap(index),
                          highlighted: _highlightedIndices.contains(index), // stays green glow
                          disappearing: _disappearingIndices.contains(index), // wont shrink on hint
                        ),
                        ),
                      );
                    },
                  ),
                ],
            ),
        ),
    );
  }
}






  //late SoundManager soundManager = SoundManager();


















