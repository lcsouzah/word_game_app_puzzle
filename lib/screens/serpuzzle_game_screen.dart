import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/serpuzzle_grid.dart';
import '../models/serpuzzle_snake.dart';
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
  late SerpuzzleGrid _grid;
  late SerpuzzleSnake _snake;
  bool _isMatched = false;
  int _score = 0;
  late WordMatchEngine _engine;
  Timer? _resetTimer;
  late int _maxWordLength;

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _maxWordLength = widget.dictionary.fold<int>(0, (p, w) => max(p, w.length));
    _initBoard();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }


  void _initBoard() {
    final rand = Random();
    _grid = SerpuzzleGrid(rows: widget.gridSize, cols: widget.gridSize);

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
            final pos = GridPosition(row, col + k);
            _grid.placeLetter(pos, word[k]);
            placed.add(indexes[k]);
          }
          placedWord = true;
        } else {
          final col = rand.nextInt(widget.gridSize);
          final maxRow = widget.gridSize - word.length;
          if (maxRow < 0) continue;
          final row = rand.nextInt(maxRow + 1);
          final indexes = List<int>.generate(
              word.length, (k) => (row + k) * widget.gridSize + col);
          if (indexes.any(placed.contains)) continue;
          for (var k = 0; k < word.length; k++) {
            final pos = GridPosition(row + k, col);
            _grid.placeLetter(pos, word[k]);
            placed.add(indexes[k]);
          }
          placedWord = true;
        }
      }
    }

    for (var i = 0; i < _grid.length; i++) {
      final pos = _grid.positionOfIndex(i);
      if (_grid.letterAt(pos).isEmpty) {
        _grid.placeLetter(pos, _randomLetter());
      }
    }

    final startPos =
    GridPosition(widget.gridSize ~/ 2, widget.gridSize ~/ 2);
    _snake = SerpuzzleSnake()
      ..append(startPos, _grid.letterAt(startPos));
  }

  void _onSwipe(DirectionEnum direction) {
    if (_isMatched) return;
    final head = _snake.segments.last;
    int row = head.row;
    int col = head.col;
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
    final newPos = GridPosition(row, col);
    if (!_grid.inBounds(newPos)) {
      return; // out of bounds
    }
    if (_snake.segments.contains(newPos)) return; // don't allow self-collision
    setState(() {
      _snake.append(newPos, _grid.letterAt(newPos));
      if (_snake.word.length > _maxWordLength) {
        _snake.clearRange(0, _snake.segments.length - 1);
      }
    });
    _validate();
    if (!_isMatched) {
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _snake.clearRange(0, _snake.segments.length - 1);
        });
      });
    }
  }

  void _validate() {
    final letters = _snake.word;
    if (_engine.matches(letters)) {
      final matchedSegments = List<GridPosition>.from(_snake.segments);
      _resetTimer?.cancel();
      setState(() {
        _score += letters.length;
        _isMatched = true;
        _snake.clearRange(0, _snake.segments.length - 1);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          for (final pos in matchedSegments) {
            _grid.placeLetter(pos, _randomLetter());
          }
          final headPos = matchedSegments.last;
          _snake
            ..clear()
            ..append(headPos, _grid.letterAt(headPos));
          _isMatched = false;
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
                final snakePositions = _snake.segments.toSet();
                final segments = _snake.segments
                    .map((pos) => SnakeSegment(
                  row: pos.row,
                  col: pos.col,
                  letter: _grid.letterAt(pos),
                  highlighted: _isMatched,
                ))
                    .toList();
                return Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.gridSize,
                      ),
                      itemCount: _grid.length,
                      itemBuilder: (context, index) {
                        final pos = _grid.positionOfIndex(index);
                        final isSnake = snakePositions.contains(pos);
                        final highlight = _isMatched && isSnake;
                        return SerpuzzleTile(
                          letter: isSnake ? '' : _grid.letterAt(pos),
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