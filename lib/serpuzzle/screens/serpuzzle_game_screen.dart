import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:word_game_app/serpuzzle/models/difficulty_level.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_snake.dart';
import 'package:word_game_app/serpuzzle/widgets/portal_animation.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_body.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_tile.dart';
import 'package:word_game_app/utils/direction_enum.dart';
import 'package:word_game_app/utils/swipe_detector.dart';

/// Very small word-matching engine. Checks if the collected letters
/// form any word in the provided [dictionary] and provides prefix lookups
/// to quickly rule out impossible paths.
class WordMatchEngine {
  final Set<String> dictionary;
  final Set<String> prefixes;

  WordMatchEngine(List<String> words)
      : dictionary = words.map((e) => e.toUpperCase()).toSet(),
        prefixes = (() {
          // Include the empty string so that an empty sequence of letters is
          // treated as a valid prefix. This allows the game logic to advance
          // over blank tiles without resetting the snake.
          final set = <String>{''};
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
  final int maxWordLength;
  final bool startCentered;
  final Duration moveDelay;
  final Duration levelTimeLimit;
  final bool wrapAround;
  final DifficultyLevel difficulty;

  const SerpuzzleGameScreen({
    super.key,
    required this.gridSize,
    required this.dictionary,
    required this.maxWordLength,
    this.startCentered = true,
    this.moveDelay = const Duration(milliseconds: 300),
    this.levelTimeLimit = const Duration(minutes: 1),
    this.wrapAround = false,
    this.difficulty = DifficultyLevel.easy,

  });

  @override
  State<SerpuzzleGameScreen> createState() => _SerpuzzleGameScreenState();
}

class _SerpuzzleGameScreenState extends State<SerpuzzleGameScreen> {
  final Random _rand = Random();
  late SerpuzzleGrid _grid;
  late SerpuzzleSnake _snake;
  bool _isMatched = false;
  bool _isPaused = false;
  int _score = 0;
  int _level = 1;
  late WordMatchEngine _engine;
  Timer? _resetTimer;
  late Duration _moveDelay;
  late int _maxWordLength;
  Timer? _moveTimer;
  Timer? _levelTimer;
  Duration _elapsed = Duration.zero;
  late Duration _timeLimit;
  Direction _currentDirection = Direction.right;
  int _growSegments = 0;
  bool _isGameOver = false;
  late List<String> _letterPool;
  int _currentTiles = 0;
  int _lives = 0;

  int get _tilesNeeded => max(0, 4 - _currentTiles);

  int _initialLivesFor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.moderate:
        return 2;
      case DifficultyLevel.hard:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _maxWordLength = widget.maxWordLength;
    _letterPool = widget.dictionary
        .expand((w) => w.toUpperCase().split(''))
        .toList();
    _moveDelay = widget.moveDelay;
    _timeLimit = widget.levelTimeLimit;
    _initBoard();
    _startMoveTimer();
    _startLevelTimer(resetElapsed: true);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _moveTimer?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(_moveDelay, (_) => _tick());
  }

  void _startLevelTimer({bool resetElapsed = false}) {
    _levelTimer?.cancel();
    if (resetElapsed) {
      _elapsed = Duration.zero;
    }
    _levelTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());
  }

  void _onTimerTick() {
    if (_isPaused || _isMatched || _isGameOver) {
      return;
    }
    _elapsed += const Duration(seconds: 1);
    if (_elapsed >= _timeLimit) {
      _elapsed = _timeLimit;
      setState(() {});
      _levelTimer?.cancel();
      _handleTimeExpired();
    } else {
      setState(() {});
    }
  }

  void _handleTimeExpired() {
    if (_isGameOver) {
      return;
    }
    _gameOver();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _moveTimer?.cancel();
        _moveTimer = null;
        _levelTimer?.cancel();
        _levelTimer = null;
      } else {
        _startMoveTimer();
        _startLevelTimer();
      }
    });
  }


  void _initBoard({bool resetLives = false}) {
    if (resetLives || _lives == 0) {
      _lives = _initialLivesFor(widget.difficulty);
    }

    _grid = SerpuzzleGrid(rows: widget.gridSize, cols: widget.gridSize);
    GridPosition startPos;
    if (widget.startCentered) {
      startPos = GridPosition(widget.gridSize ~/ 2, widget.gridSize ~/ 2);
    } else {
      startPos = GridPosition(
          _rand.nextInt(widget.gridSize), _rand.nextInt(widget.gridSize));
    }
    _snake = SerpuzzleSnake()..append(startPos, '');
    _growSegments = _maxWordLength - 1;
    _currentTiles = 0;
    _currentDirection = Direction.right;
    _spawnRandomTiles(_tilesNeeded);
  }

  void _resetGame() {
    _resetTimer?.cancel();
    setState(() {
      _score = 0;
      _isMatched = false;
      _level = 1;
      _initBoard(resetLives: true);
      _isGameOver = false;
      _startLevelTimer(resetElapsed: true);
    });
    _startMoveTimer();
  }

  void _handleCollision() {
    _resetTimer?.cancel();
    if (_lives <= 1) {
      setState(() {
        _lives = 0;
      });
      _gameOver();
      return;
    }
    setState(() {
      _lives--;
      _isMatched = false;
      _initBoard();
    });
  }

  Future<void> _gameOver() async {
    if (_isGameOver) return;
    _isGameOver = true;
    _levelTimer?.cancel();
    _moveTimer?.cancel();
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
    if (_isPaused || _isMatched || _isGameOver) return;
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

    if (widget.wrapAround) {
      final rows = _grid.rows;
      final cols = _grid.cols;
      row = ((row % rows) + rows) % rows;
      col = ((col % cols) + cols) % cols;
    }

    final newPos = GridPosition(row, col);
    if (!_grid.inBounds(newPos) || _snake.segments.contains(newPos)) {
      _handleCollision();
      return;
    }
    final letter = _grid.letterAt(newPos);
    if (letter.isNotEmpty) {
      _growSegments++;
      _grid.placeLetter(newPos, '');
      _currentTiles--;
    }
    final potentialWord = _snake.word + letter;
    if (!_engine.hasPrefix(potentialWord)) {
      _resetTimer?.cancel();
      setState(() {
        _snake
          ..clear()
          ..append(newPos, '');
        _growSegments = _maxWordLength - 1;
        _spawnRandomTiles(_tilesNeeded);
      });
      return;
    }

    setState(() {
      _snake.append(newPos, letter);
      if (_growSegments > 0) {
        _growSegments--;
      } else if (_snake.segments.length > 1) {
        _snake.dropFirstBlankSegment();
      }
      while (_snake.word.length > _maxWordLength &&
          _snake.segments.length > 1) {
        _snake.clearRange(0, 1);
      }
      if (letter.isNotEmpty) {
        _spawnRandomTiles(_tilesNeeded);
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
          _spawnRandomTiles(_tilesNeeded);
        });
      });
    }
  }

  void _onSwipe(Direction direction) {
    if (_isMatched || _isGameOver) return;
    if (_isOppositeDirection(direction, _currentDirection)) return;
    _currentDirection = direction;
  }

  bool _isOppositeDirection(Direction a, Direction b) {
    switch (a) {
      case Direction.up:
        return b == Direction.down;
      case Direction.down:
        return b == Direction.up;
      case Direction.left:
        return b == Direction.right;
      case Direction.right:
        return b == Direction.left;
    }
  }

  void _validate() {
    final letters = _snake.word;
    if (_engine.matches(letters)) {
      _resetTimer?.cancel();
      setState(() {
        _score += letters.length;
        _isMatched = true;
        _level++;
      });
      _showLevelTransition();
    }
  }

  Future<void> _showLevelTransition() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PortalAnimation(level: _level),
    );
    if (!mounted) return;
    setState(() {
      _isMatched = false;
      _initBoard();
      _startLevelTimer(resetElapsed: true);
    });
  }

  String get _formattedTimeRemaining {
    final remaining = _timeLimit - _elapsed;
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _randomLetter() {
    return _letterPool[_rand.nextInt(_letterPool.length)];
  }

  /// Minimum Manhattan distance a spawned tile must maintain from the snake.
  static const int _minSpawnDistance = 2;

  /// Selects a random word (up to four letters) from the dictionary and
  /// places its letters on the board. Any remaining slots are filled with
  /// random letters. This guarantees that at least one valid word can always
  /// be formed from the visible tiles.
  void _spawnRandomTiles(int count) {
    if (count <= 0) return;

    final empties = <GridPosition>[];
    for (var i = 0; i < _grid.length; i++) {
      final pos = _grid.positionOfIndex(i);
      if (_grid.letterAt(pos).isEmpty && !_snake.segments.contains(pos)) {
        empties.add(pos);
      }
    }
    if (empties.isEmpty) {
      return;
    }

    final farPositions = empties
        .where((pos) => _isFarFromSnake(pos, _snake.segments))
        .toList();
    final spawnPositions = farPositions.isNotEmpty ? farPositions : empties;
    spawnPositions.shuffle(_rand);

    final spawnCount = min(count, spawnPositions.length);
    if (spawnCount <= 0) {
      return;
    }

    final maxWordLength = min(4, spawnCount);
    final candidates = widget.dictionary
        .where((w) => w.isNotEmpty && w.length <= maxWordLength)
        .toList();
    String? target;
    if (candidates.isNotEmpty) {
      target =
          candidates[_rand.nextInt(candidates.length)].toUpperCase();
    }

    final letters = <String>[];
    if (target != null) {
      letters.addAll(target.split(''));
    }
    while (letters.length < spawnCount) {
      letters.add(_randomLetter());
    }
    letters.shuffle(_rand);

    for (var i = 0; i < spawnCount; i++) {
      _grid.placeLetter(spawnPositions[i], letters[i]);
    }
    _currentTiles += spawnCount;
  }

  bool _isFarFromSnake(GridPosition pos, List<GridPosition> segments) {
    for (final segment in segments) {
      if (_manhattanDistance(pos, segment) < _minSpawnDistance) {
        return false;
      }
    }
    return true;
  }

  int _manhattanDistance(GridPosition a, GridPosition b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level $_level - Score: $_score'),
            Text('Time: $_formattedTimeRemaining',
                style: Theme.of(context).textTheme.bodySmall),
            Text('Lives: $_lives',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: Center(
        child: SwipeDetector(
          onSwipe: _onSwipe,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const snakeScale = 0.75;
                final availableSize =
                min(constraints.maxWidth, constraints.maxHeight);
                final boardSize =
                availableSize.isFinite ? availableSize : constraints.maxWidth;
                final tileSize = boardSize / widget.gridSize;
                final snakeTileSize = tileSize * snakeScale;
                final snakePositions = _snake.segments.toSet();
                final letters = _snake.letters;
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
                final boardExtent = tileSize * widget.gridSize;
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: boardExtent,
                    height: boardExtent,
                    child: Stack(
                      children: [
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
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
                          tileSize: snakeTileSize,
                          segmentScale: snakeScale,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @visibleForTesting
  SerpuzzleSnake get snake => _snake;

  @visibleForTesting
  SerpuzzleGrid get grid => _grid;

  @visibleForTesting
  int get growSegments => _growSegments;

  @visibleForTesting
  void setGrowSegmentsForTest(int value) {
    _growSegments = value;
  }

  @visibleForTesting
  void setDirectionForTest(Direction direction) {
    _currentDirection = direction;
  }

  @visibleForTesting
  void tickForTest() => _tick();

  @visibleForTesting
  void cancelTimersForTest() {
    _moveTimer?.cancel();
    _resetTimer?.cancel();
    _levelTimer?.cancel();
  }

  @visibleForTesting
  Duration get moveDelayForTest => _moveDelay;

  @visibleForTesting
  Duration get elapsedForTest => _elapsed;

  @visibleForTesting
  void clearGridLettersForTest() {
    for (var i = 0; i < _grid.length; i++) {
      final pos = _grid.positionOfIndex(i);
      _grid.placeLetter(pos, '');
    }
    _currentTiles = 0;
  }

  @visibleForTesting
  void setCurrentTilesForTest(int value) {
    _currentTiles = value;
  }
  @visibleForTesting
  void spawnRandomTilesForTest(int count) {
    _spawnRandomTiles(count);
  }

  @visibleForTesting
  int get currentTilesForTest => _currentTiles;

  @visibleForTesting
  int get minSpawnDistanceForTest => _minSpawnDistance;

  @visibleForTesting
  bool get isGameOverForTest => _isGameOver;

  @visibleForTesting
  int get livesForTest => _lives;

}
