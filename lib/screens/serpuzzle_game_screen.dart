import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/serpuzzle_grid.dart';
import '../models/serpuzzle_snake.dart';
import '../widgets/serpuzzle_snake_body.dart';
import '../widgets/serpuzzle_tile.dart';
import '../utils/direction_enum.dart';
import '../utils/swipe_detector.dart';


/// Very small word-matching engine. Checks if the collected letters
/// form any word in the provided [dictionary] and provides prefix lookups
/// to quickly rule out impossible paths.
class WordMatchEngine {
  final Set<String> dictionary;
  final Set<String> prefixes;

  WordMatchEngine(List<String> words)
      : dictionary = words.map((e) => e.toUpperCase()).toSet(),
        prefixes = (() {
          final set = <String>{};
          for (final w in words) {
            final upper = w.toUpperCase();
            for (var i = 1; i <= upper.length; i++) {
              set.add(upper.substring(0, i));
            }
          }
          return set;
        })();

  bool matches(String letters) => dictionary.contains(letters.toUpperCase());

  /// Returns `true` if [letters] is a prefix of any word in [dictionary].
  bool hasPrefix(String letters) => prefixes.contains(letters.toUpperCase());
}

/// Serpuzzle game screen showing the grid and handling swipe input.
class SerpuzzleGameScreen extends StatefulWidget {
  final int gridSize;
  final List<String> dictionary;
  final int seededWordCount;
  final bool startCentered;

  const SerpuzzleGameScreen({
    super.key,
    required this.gridSize,
    required this.dictionary,
    this.seededWordCount = 1,
    this.startCentered = true,
  });

  @override
  State<SerpuzzleGameScreen> createState() => _SerpuzzleGameScreenState();
}

class _SerpuzzleGameScreenState extends State<SerpuzzleGameScreen> {
  final Random _rand = Random();
  late SerpuzzleGrid _grid;
  late SerpuzzleSnake _snake;
  bool _isMatched = false;
  int _score = 0;
  late WordMatchEngine _engine;
  Timer? _resetTimer;
  late int _maxWordLength;
  Timer? _moveTimer;
  Direction _currentDirection = Direction.right;
  int _growSegments = 0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _maxWordLength = widget.dictionary.fold<int>(0, (p, w) => max(p, w.length));
    _initBoard();
    _moveTimer =
        Timer.periodic(const Duration(milliseconds: 300), (_) => _tick());
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }


  void _initBoard() {
    final rand = Random();
    _grid = SerpuzzleGrid(rows: widget.gridSize, cols: widget.gridSize);

    final placed = <int>{};
    final words = List<String>.from(widget.dictionary)..shuffle(rand);
    final wordsToPlace = min(widget.seededWordCount, words.length);
    GridPosition? wordStartPos;

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
          wordStartPos ??= GridPosition(row, col);
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
          wordStartPos ??= GridPosition(row, col);
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

    GridPosition startPos;
    if (widget.startCentered) {
      startPos = GridPosition(widget.gridSize ~/ 2, widget.gridSize ~/ 2);
    } else if (wordStartPos != null) {
      startPos = wordStartPos;
    } else {
      startPos = GridPosition(
          rand.nextInt(widget.gridSize), rand.nextInt(widget.gridSize));
    }
    _snake = SerpuzzleSnake()
      ..append(startPos, '');
    _growSegments = _maxWordLength - 1;
  }

  void _resetGame() {
    _resetTimer?.cancel();
    setState(() {
      _score = 0;
      _isMatched = false;
      _initBoard();
      _isGameOver = false;
    });
  }

  Future<void> _gameOver() async {
    if (_isGameOver) return;
    _isGameOver = true;
    final finalScore = _score;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Final score: $finalScore'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _resetGame();
  }

  void _tick() {
    if (_isMatched || _isGameOver) return;
    final head = _snake.segments.last;
    int row = head.row;
    int col = head.col;
    switch (_currentDirection) {
      case Direction.up:
        row -= 1;
        break;
      case Direction.down:
        row += 1;
        break;
      case Direction.left:
        col -= 1;
        break;
      case Direction.right:
        col += 1;
        break;
    }
    final newPos = GridPosition(row, col);
    if (!_grid.inBounds(newPos) || _snake.segments.contains(newPos)) {
      _gameOver();
      return;
    }
    final letter = _grid.letterAt(newPos);
    final potentialWord = _snake.word + letter;
    if (!_engine.hasPrefix(potentialWord)) {
      _resetTimer?.cancel();
      setState(() {
        _snake
          ..clear()
          ..append(newPos, '');
        _growSegments = _maxWordLength - 1;
      });
      return;
    }

    setState(() {
      _snake.append(newPos, letter);
      if (_growSegments > 0) {
        _growSegments--;
      } else if (_snake.segments.length > 1) {
        _snake.clearRange(0, 1);
      }
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
          final headPos = _snake.segments.last;
          _snake
            ..clear()
            ..append(headPos, '');
          _growSegments = _maxWordLength - 1;
        });
      });
    }
  }

  void _onSwipe(Direction direction) {
    if (_isMatched || _isGameOver) return;
    final head = _snake.segments.last;
    int row = head.row;
    int col = head.col;
    switch (direction) {
      case Direction.up:
        row -= 1;
        break;
      case Direction.down:
        row += 1;
        break;
      case Direction.left:
        col -= 1;
        break;
      case Direction.right:
        col += 1;
        break;
    }
    final newPos = GridPosition(row, col);
    if (!_grid.inBounds(newPos) || _snake.segments.contains(newPos)) {
      _gameOver();
      return;
    }
    _currentDirection = direction;
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
        _growSegments = _maxWordLength - 1;
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
            ..append(headPos, '');
          _isMatched = false;
          _growSegments = _maxWordLength - 1;
        });
      });
    }
  }

  String _randomLetter() {
    return String.fromCharCode(65 + _rand.nextInt(26));
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
                final letters = _snake.word;
                final segments = <SnakeSegment>[];
                for (var i = 0; i < _snake.segments.length; i++) {
                  final pos = _snake.segments[i];
                  final isHead = i == _snake.segments.length - 1;
                  segments.add(SnakeSegment(
                    row: pos.row,
                    col: pos.col,
                    letter: isHead ? '' : letters[i],
                    highlighted: _isMatched,
                  ));
                }
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