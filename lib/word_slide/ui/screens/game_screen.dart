//Y:\word_game_app_puzzle\lib\screens\game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alphabet_game.dart';
import '../utils/pause_manager.dart';
import '../utils/sound_manager.dart';
import '../widgets/tap_feedback_overlay.dart';
import '../widgets/tile.dart';

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
  // Pulsing animation for hint button (when hints are available).
  late AnimationController _hintButtonController;
  late Animation<double> _hintButtonAnimation;

  // Hint state tracked locally to keep it deterministic per match.
  late int _hintsUsed;
  late int _maxHints;

  // Basic metrics.
  int moveCounter = 0;

  // Animation layers for tiles. Sets prevent duplicate indices.
  final Set<int> _highlightedIndices = <int>{};
  final Set<int> _disappearingIndices = <int>{};

  // Concurrency guards: prevent overlapping animations from fighting each other.
  bool _isHintAnimating = false;
  bool _isResolvingCorrectWord = false;

  // Cosmetic controls are intentionally isolated from gameplay states.
  // Update these later without touching hint/correct-word logic.
  static const Color _tileBorderColor = Color(0x66FFFFFF);
  static const double _tileBorderWidth = 1.2;

  @override
  void initState() {
    super.initState();
    _maxHints = widget.maxHints;
    _hintsUsed = 0;

    _hintButtonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _hintButtonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hintButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hintButtonController.dispose();
    super.dispose();
  }

  void addHints(int amount) {
    setState(() {
      _maxHints += amount;

      // If user had exhausted hints, restore just enough room to use new hints.
      if (_hintsUsed >= _maxHints) {
        _hintsUsed = _maxHints - amount;
      }

      _hintsUsed = _hintsUsed.clamp(0, _maxHints);
      debugPrint('🧠 addHints called: maxHints=$_maxHints | hintsUsed=$_hintsUsed');
    });
  }

  void _handleTileTap(int index) {
    final pauseManager = Provider.of<PauseManager>(context, listen: false);

    // Manual pause always blocks interaction.
    if (pauseManager.isPaused && pauseManager.pauseReason == PauseReason.manual) {
      return;
    }

    // Non-manual pause (e.g. transient state) auto-resumes on interaction.
    if (pauseManager.isPaused && pauseManager.pauseReason != PauseReason.manual) {
      pauseManager.forceResume();
    }

    // Ignore taps while a solved word is resolving to avoid state races.
    if (_isResolvingCorrectWord) return;

    final didMove = widget.game.moveTile(index);
    if (!didMove) return;

    SoundManager.playSound('tileMove');
    moveCounter++;
    setState(() {});

    _checkWord();
  }

  String? _findClosestWord(List<String> boardLetters) {
    int bestScore = 0;
    String? bestMatch;

    // NOTE: Current strategy is prefix-only matching.
    // TODO(logic): Consider edit-distance or positional weighting later.
    for (final word in widget.dictionary) {
      int score = 0;
      for (int i = 0; i < word.length && i < boardLetters.length; i++) {
        if (word[i] == boardLetters[i]) {
          score++;
        } else {
          break;
        }
      }

      if (score > bestScore && score >= 2) {
        bestScore = score;
        bestMatch = word;
      }
    }

    return bestMatch;
  }

  /// Returns tile indices that match [word] in board-read order.
  List<int> _findMatchingIndices(String word, {bool vertical = false}) {
    final List<int> indices = [];
    final tiles = widget.game.letters;
    int matchIndex = 0;

    const int gridSize = 4;

    if (vertical) {
      for (int col = 0; col < gridSize && matchIndex < word.length; col++) {
        for (int row = 0; row < gridSize && matchIndex < word.length; row++) {
          final int i = row * gridSize + col;
          if (tiles[i] == ' ') return indices;
          if (tiles[i] == word[matchIndex]) {
            indices.add(i);
            matchIndex++;
          }
        }
      }
    } else {
      for (int i = 0; i < tiles.length && matchIndex < word.length; i++) {
        if (tiles[i] == ' ') break;
        if (tiles[i] == word[matchIndex]) {
          indices.add(i);
          matchIndex++;
        }
      }
    }

    return indices;
  }

  Future<void> _showHint() async {
    // Prevent hint animation overlap with itself or solved-word effects.
    if (_isHintAnimating || _isResolvingCorrectWord) return;

    debugPrint('💡 Requesting hint → hintsUsed: $_hintsUsed | maxHints: $_maxHints');

    if (_hintsUsed >= _maxHints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have used all your hints.')),
      );
      return;
    }

    final List<String> boardLetters = <String>[];
    for (final letter in widget.game.letters) {
      if (letter != ' ') boardLetters.add(letter);
    }

    final String? hintWord = _findClosestWord(boardLetters);
    if (hintWord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No obvious hints available right now.')),
      );
      return;
    }

    _isHintAnimating = true;
    _hintsUsed++;

    final indices = _findMatchingIndices(hintWord);

    if (!mounted) return;
    setState(() {
      _highlightedIndices
        ..clear()
        ..addAll(indices);
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _highlightedIndices.clear();
    });

    _isHintAnimating = false;
  }

  Future<void> _checkWord() async {
    if (_isResolvingCorrectWord) return;

    // Collect formed words with orientation.
    final List<Map<String, dynamic>> formedWords = [];

    switch (widget.scoringOption) {
      case ScoringOption.horizontal:
        formedWords.add({'word': widget.game.getWord(), 'vertical': false});
        break;
      case ScoringOption.vertical:
        formedWords.add({'word': widget.game.getWordVertical(), 'vertical': true});
        break;
      case ScoringOption.both:
        formedWords.add({'word': widget.game.getWord(), 'vertical': false});
        formedWords.add({'word': widget.game.getWordVertical(), 'vertical': true});
        break;
    }

    for (final entry in formedWords) {
      final String word = entry['word'] as String;
      final bool vertical = entry['vertical'] as bool;

      if (!widget.dictionary.contains(word)) continue;

      _isResolvingCorrectWord = true;
      widget.onCorrectWord(word);
      debugPrint('🎉 Matched word: $word');

      final indices = _findMatchingIndices(word, vertical: vertical);

      // Sequential hint-like highlight.
      for (int i = 0; i < indices.length; i++) {
        await Future.delayed(Duration(milliseconds: 120 * i), () {
          if (!mounted) return;
          setState(() {
            _highlightedIndices.add(indices[i]);
          });
        });
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Sequential disappear animation.
      for (int i = 0; i < indices.length; i++) {
        await Future.delayed(Duration(milliseconds: 50 * i), () {
          if (!mounted) return;
          setState(() {
            _highlightedIndices.remove(indices[i]);
            _disappearingIndices.add(indices[i]);
          });
        });
      }

      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;
      setState(() {
        _disappearingIndices.clear();
        widget.game.clearWord();
        widget.game.generateNewLetters();
      });

      _isResolvingCorrectWord = false;
      return;
    }

    // No valid word formed.
    debugPrint('The formed word is not correct. $formedWords');
  }

  @override
  Widget build(BuildContext context) {
    final pauseManager = Provider.of<PauseManager>(context);

    final canUseHint = _hintsUsed < _maxHints;
    final canUseAd = widget.adUsesThisMatch < widget.maxAdUsesPerMatch;

    String label;
    Icon icon;

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
                backgroundColor: canUseHint ? Colors.amber : Colors.grey,
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
                      key: ValueKey('$letter-$index'),
                      letter: letter,
                      onTap: () => _handleTileTap(index),
                      highlighted: _highlightedIndices.contains(index),
                      disappearing: _disappearingIndices.contains(index),
                      borderColor: _tileBorderColor,
                      borderWidth: _tileBorderWidth,
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




