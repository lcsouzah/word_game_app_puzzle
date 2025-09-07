import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/serpuzzle_snake_body.dart';
import '../widgets/serpuzzle_tile.dart';

/// Direction values used by [SwipeDetector].
enum DirectionEnum { up, down, left, right }

/// Simple gesture detector that converts a swipe into a [DirectionEnum].
class SwipeDetector extends StatelessWidget {
  final Widget child;
  final void Function(DirectionEnum) onSwipe;

  const SwipeDetector({super.key, required this.child, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dx.abs() > velocity.dy.abs()) {
          onSwipe(velocity.dx > 0 ? DirectionEnum.right : DirectionEnum.left);
        } else {
          onSwipe(velocity.dy > 0 ? DirectionEnum.down : DirectionEnum.up);
        }
      },
      child: child,
    );
  }
}



/// Very small word-matching engine. Checks if the collected letters
/// form any word in the provided [dictionary].
class WordMatchEngine {
  final Set<String> dictionary;

  WordMatchEngine(List<String> words)
      : dictionary = words.map((e) => e.toUpperCase()).toSet();

  bool matches(String letters) => dictionary.contains(letters.toUpperCase());
}

/// Serpuzzle game screen showing the grid and handling swipe input.
class SerpuzzleGameScreen extends StatefulWidget {
  final int gridSize;
  final List<String> dictionary;
  final int seededWordCount;

  const SerpuzzleGameScreen({
    super.key,
    required this.gridSize,
    required this.dictionary,
    this.seededWordCount = 1,
  });

  @override
  State<SerpuzzleGameScreen> createState() => _SerpuzzleGameScreenState();
}

class _SerpuzzleGameScreenState extends State<SerpuzzleGameScreen> {
  late List<String> _letters;
  late List<int> _snake;
  final Set<int> _matched = {};
  int _score = 0;
  late WordMatchEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _initBoard();
  }

  void _initBoard() {
    final rand = Random();
    final totalCells = widget.gridSize * widget.gridSize;
    _letters = List.filled(totalCells, '');

    final placed = <int>{};
    final words = List<String>.from(widget.dictionary)..shuffle(rand);
    final wordsToPlace = min(widget.seededWordCount, words.length);

    for (var i = 0; i < wordsToPlace; i++) {
      final word = words[i].toUpperCase();
      bool placedWord = false;
      for (var attempt = 0; attempt < 100 && !placedWord; attempt++) {
        final horizontal = rand.nextBool();
        if (horizontal) {
          final row = rand.nextInt(widget.gridSize);
          final maxCol = widget.gridSize - word.length;
          if (maxCol < 0) continue;
          final col = rand.nextInt(maxCol + 1);
          final indexes =
          List<int>.generate(word.length, (k) => row * widget.gridSize + col + k);
          if (indexes.any(placed.contains)) continue;
          for (var k = 0; k < word.length; k++) {
            _letters[indexes[k]] = word[k];
            placed.add(indexes[k]);
          }
          placedWord = true;
        } else {
          final col = rand.nextInt(widget.gridSize);
          final maxRow = widget.gridSize - word.length;
          if (maxRow < 0) continue;
          final row = rand.nextInt(maxRow + 1);
          final indexes =
          List<int>.generate(word.length, (k) => (row + k) * widget.gridSize + col);
          if (indexes.any(placed.contains)) continue;
          for (var k = 0; k < word.length; k++) {
            _letters[indexes[k]] = word[k];
            placed.add(indexes[k]);
          }
          placedWord = true;
        }
      }
    }

    for (var i = 0; i < _letters.length; i++) {
      if (_letters[i].isEmpty) {
        _letters[i] = _randomLetter();
      }
    }


    final start = (widget.gridSize ~/ 2) * widget.gridSize + widget.gridSize ~/ 2;
    _snake = [start];
  }

  void _onSwipe(DirectionEnum direction) {
    final head = _snake.last;
    int row = head ~/ widget.gridSize;
    int col = head % widget.gridSize;
    switch (direction) {
      case DirectionEnum.up:
        row -= 1;
        break;
      case DirectionEnum.down:
        row += 1;
        break;
      case DirectionEnum.left:
        col -= 1;
        break;
      case DirectionEnum.right:
        col += 1;
        break;
    }
    if (row < 0 || col < 0 || row >= widget.gridSize || col >= widget.gridSize) {
      return; // out of bounds
    }
    final newIndex = row * widget.gridSize + col;
    if (_snake.contains(newIndex)) return; // don't allow self-collision
    setState(() {
      _snake.add(newIndex);
      _validate();
    });
  }

  void _validate() {
    final letters = _snake.map((i) => _letters[i]).join();
    if (_engine.matches(letters)) {
      _matched.addAll(_snake);
      _score += letters.length;
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          for (final index in _matched) {
            _letters[index] = _randomLetter();
          }
          _matched.clear();
          _snake = [_snake.last];
        });
      });
    }
  }

  String _randomLetter() {
    final rand = Random();
    return String.fromCharCode(65 + rand.nextInt(26));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Score: $_score')),
      body: Center(
        child: SwipeDetector(
          onSwipe: _onSwipe,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = constraints.maxWidth / widget.gridSize;
                final snakeSet = _snake.toSet();
                final segments = _snake.map((index) {
                  final row = index ~/ widget.gridSize;
                  final col = index % widget.gridSize;
                  return SnakeSegment(
                    row: row,
                    col: col,
                    letter: _letters[index],
                    highlighted: _matched.contains(index),
                  );
                }).toList();
                return Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.gridSize,
                      ),
                      itemCount: _letters.length,
                      itemBuilder: (context, index) {
                        final highlight = _matched.contains(index);
                        final isSnake = snakeSet.contains(index);
                        return SerpuzzleTile(
                          letter: isSnake ? '' : _letters[index],
                          highlighted: highlight,
                        );
                      },
                    ),
                    SerpuzzleSnakeBody(
                      segments: segments,
                      tileSize: tileSize,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}