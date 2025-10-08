import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_snake.dart';
import 'package:word_game_app/utils/direction_enum.dart';

class WordMatchEngine {
  final Set<String> dictionary;
  final Set<String> prefixes;

  WordMatchEngine(List<String> words)
      : dictionary = words.map((e) => e.toUpperCase()).toSet(),
        prefixes = (() {
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

  bool hasPrefix(String letters) => prefixes.contains(letters.toUpperCase());
}

class SerpuzzleGameController extends ChangeNotifier {
  SerpuzzleGameController({
    required this.levelTimeLimit,
    required this.initialLives,
    required this.gridSize,
    required List<String> dictionary,
    required int maxWordLength,
    this.startCentered = true,
    this.moveDelay = const Duration(milliseconds: 300),
    this.wrapAround = false,
  })  : _lives = initialLives,
        _maxWordLength = maxWordLength,
        _engine = WordMatchEngine(dictionary),
        _letterPool = dictionary
            .expand((w) => w.toUpperCase().split(''))
            .toList(),
        _safeStartLetters = dictionary
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .toSet(),
        isPausedNotifier = ValueNotifier(false) {
    initializeGame();
  }

  final Duration levelTimeLimit;
  final int initialLives;
  final int gridSize;
  final bool startCentered;
  final Duration moveDelay;
  final bool wrapAround;

  final ValueNotifier<int> gridNotifier = ValueNotifier(0);
  final ValueNotifier<int> snakeNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isMatchedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isPausedNotifier;

  final WordMatchEngine _engine;
  final Random _rand = Random();
  final List<String> _letterPool;
  final Set<String> _safeStartLetters;
  late final List<String> _safeStartLetterList = _safeStartLetters.toList();

  static const int _minSpawnDistance = 2;

  SerpuzzleGrid _grid = SerpuzzleGrid(rows: 0, cols: 0);
  SerpuzzleSnake _snake = SerpuzzleSnake();

  Timer? _levelTimer;
  Timer? _moveTimer;
  Timer? _resetTimer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _isGameOver = false;
  int _score = 0;
  int _level = 1;
  int _lives;
  final int _maxWordLength;
  bool _consumeSpawnOnNextTick = false;
  bool _isMovementReady = false;
  Direction _currentDirection = Direction.right;
  Direction? _pendingDirection;
  int _growSegments = 0;
  int _currentTiles = 0;
  bool _disposed = false;

  VoidCallback? onTimeExpired;
  VoidCallback? onGameOver;

  SerpuzzleGrid get grid => _grid;
  SerpuzzleSnake get snake => _snake;

  int get score => _score;
  int get level => _level;
  int get lives => _lives;
  Duration get elapsed => _elapsed;
  bool get isPaused => _isPaused;
  bool get isGameOver => _isGameOver;
  bool get isMatched => isMatchedNotifier.value;

  ValueListenable<bool> get isPausedListenable => isPausedNotifier;
  ValueListenable<bool> get isMatchedListenable => isMatchedNotifier;
  ValueListenable<bool> get isGameOverListenable => isGameOverNotifier;
  ValueListenable<int> get gridListenable => gridNotifier;
  ValueListenable<int> get snakeListenable => snakeNotifier;

  Duration get remainingTime {
    final remaining = levelTimeLimit - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get formattedRemaining {
    final remaining = remainingTime;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void initializeGame() {
    _initBoard();
  }

  void startLevelTimer({bool resetElapsed = false}) {
    _levelTimer?.cancel();
    if (resetElapsed) {
      _elapsed = Duration.zero;
      notifyListeners();
    }
    if (_isPaused || _isGameOver) {
      return;
    }
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isGameOver) {
        return;
      }
      _elapsed += const Duration(seconds: 1);
      if (_elapsed >= levelTimeLimit) {
        _elapsed = levelTimeLimit;
        notifyListeners();
        _levelTimer?.cancel();
        markGameOver();
        onTimeExpired?.call();
      } else {
        notifyListeners();
      }
    });
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    isPausedNotifier.value = true;
    _levelTimer?.cancel();
    _moveTimer?.cancel();
    _moveTimer = null;
    notifyListeners();
  }

  void resume() {
    if (!_isPaused || _isGameOver) return;
    _isPaused = false;
    isPausedNotifier.value = false;
    notifyListeners();
    startLevelTimer();
    _startMoveTimer();
  }

  void togglePause() {
    if (_isPaused) {
      resume();
    } else {
      pause();
    }
  }

  void addScore(int amount) {
    _score += amount;
    notifyListeners();
  }

  void advanceLevel() {
    _level += 1;
    notifyListeners();
  }

  bool consumeLife() {
    if (_lives <= 1) {
      _lives = 0;
      notifyListeners();
      return false;
    }
    _lives -= 1;
    notifyListeners();
    return true;
  }

  void grantBonusLife() {
    _lives += 1;
    notifyListeners();
  }

  void queueDirection(Direction direction) {
    if (isMatched || _isGameOver || _isPaused) return;
    final activeDirection = _pendingDirection ?? _currentDirection;
    if (_isOppositeDirection(direction, activeDirection)) return;
    _pendingDirection = direction;
    if (!_isMovementReady) {
      _isMovementReady = true;
      _startMoveTimer();
    }
  }

  void prepareNextLevel() {
    if (!isMatched) return;
    isMatchedNotifier.value = false;
    _resetTimer?.cancel();
    _resetTimer = null;
    _initBoard();
    startLevelTimer(resetElapsed: true);
  }

  void resetForNewGame({bool startTimer = true}) {
    _score = 0;
    _level = 1;
    _lives = initialLives;
    _elapsed = Duration.zero;
    _isGameOver = false;
    _isPaused = false;
    isGameOverNotifier.value = false;
    isMatchedNotifier.value = false;
    isPausedNotifier.value = false;
    _moveTimer?.cancel();
    _moveTimer = null;
    _resetTimer?.cancel();
    _resetTimer = null;
    notifyListeners();
    _levelTimer?.cancel();
    if (startTimer) {
      startLevelTimer(resetElapsed: true);
    }
    _initBoard();
  }

  void markGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    isGameOverNotifier.value = true;
    _moveTimer?.cancel();
    _moveTimer = null;
    _resetTimer?.cancel();
    _resetTimer = null;
    _levelTimer?.cancel();
    notifyListeners();
    onGameOver?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _levelTimer?.cancel();
    _moveTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  int get _tilesNeeded => max(0, 4 - _currentTiles);

  void _startMoveTimer() {
    if (!_isMovementReady || _isPaused || isMatched || _isGameOver) {
      return;
    }
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(moveDelay, (_) => _tick());
  }

  void _tick() {
    if (_isPaused || isMatched || _isGameOver || !_isMovementReady) {
      return;
    }
    if (_pendingDirection != null) {
      _currentDirection = _pendingDirection!;
      _pendingDirection = null;
      if (_consumeSpawnOnNextTick) {
        _consumeSpawnOnNextTick = false;
        return;
      }
    }

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

    if (wrapAround) {
      final rows = _grid.rows;
      final cols = _grid.cols;
      row = ((row % rows) + rows) % rows;
      col = ((col % cols) + cols) % cols;
    }

    final newPos = GridPosition(row, col);
    final segments = _snake.segments;
    final letters = _snake.letters;
    final bool willDropTailBlank = _growSegments <= 0 &&
        segments.length > 1 &&
        letters.isNotEmpty &&
        letters.first.isEmpty;
    final bool collidesWithBody = segments.contains(newPos);
    final bool collidesWithTail = collidesWithBody &&
        segments.isNotEmpty &&
        newPos == segments.first &&
        willDropTailBlank;

    if (!_grid.inBounds(newPos) || (collidesWithBody && !collidesWithTail)) {
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
      _resetTimer = null;
      if (!consumeLife()) {
        markGameOver();
        return;
      }
      _snake
        ..clear()
        ..append(newPos, '');
      _growSegments = _maxWordLength - 1;
      _spawnRandomTiles(_tilesNeeded);
      snakeNotifier.value++;
      gridNotifier.value++;
      return;
    }

    _snake.append(newPos, letter);
    if (letter.isNotEmpty) {
      _snake.transferHeadLetterToPrevious();
    }

    if (_growSegments > 0) {
      _growSegments--;
    } else if (_snake.segments.length > 1) {
      _snake.dropFirstBlankSegment();
    }

    while (_snake.word.length > _maxWordLength && _snake.segments.length > 1) {
      _snake.clearRange(0, 1);
    }
    _snake.alignLettersBehindHead();
    if (letter.isNotEmpty) {
      _spawnRandomTiles(_tilesNeeded);
      gridNotifier.value++;
    }

    snakeNotifier.value++;
    _validate();

    if (!isMatched) {
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (_disposed || _isGameOver || isMatched) return;
        final headPos = _snake.segments.last;
        _snake
          ..clear()
          ..append(headPos, '');
        _growSegments = _maxWordLength - 1;
        _spawnRandomTiles(_tilesNeeded);
        snakeNotifier.value++;
        gridNotifier.value++;
      });
    }
  }

  void _handleCollision() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _moveTimer?.cancel();
    _moveTimer = null;
    if (!consumeLife()) {
      markGameOver();
      return;
    }
    _initBoard();
  }

  void _validate() {
    final letters = _snake.word;
    if (letters.isEmpty) {
      return;
    }
    if (_engine.matches(letters)) {
      _resetTimer?.cancel();
      _resetTimer = null;
      if (!isMatched) {
        isMatchedNotifier.value = true;
        _moveTimer?.cancel();
        _moveTimer = null;
        addScore(letters.length);
        advanceLevel();
      }
    }
  }

  void _initBoard() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _moveTimer?.cancel();
    _moveTimer = null;
    _grid = SerpuzzleGrid(rows: gridSize, cols: gridSize);
    GridPosition startPos;
    if (startCentered) {
      startPos = GridPosition(gridSize ~/ 2, gridSize ~/ 2);
    } else {
      startPos = GridPosition(
        _rand.nextInt(gridSize),
        _rand.nextInt(gridSize),
      );
    }
    _snake = SerpuzzleSnake()..append(startPos, '');
    _growSegments = _maxWordLength - 1;
    _currentTiles = 0;
    _currentDirection = Direction.right;
    _pendingDirection = _currentDirection;
    _consumeSpawnOnNextTick = true;
    _isMovementReady = false;
    isMatchedNotifier.value = false;
    _spawnRandomTiles(_tilesNeeded);
    gridNotifier.value++;
    snakeNotifier.value++;
  }

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
    final candidates = _engine.dictionary
        .where((w) => w.isNotEmpty && w.length <= maxWordLength)
        .toList();
    String? target;
    if (candidates.isNotEmpty) {
      target = candidates[_rand.nextInt(candidates.length)].toUpperCase();
    }

    final letters = <String>[];
    if (target != null) {
      letters.addAll(target.split(''));
    }
    while (letters.length < spawnCount) {
      letters.add(_randomSafeStartLetter());
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

  String _randomLetter() {
    if (_letterPool.isEmpty) {
      return '';
    }
    return _letterPool[_rand.nextInt(_letterPool.length)];
  }

  String _randomSafeStartLetter() {
    if (_safeStartLetterList.isEmpty) {
      return _randomLetter();
    }
    return _safeStartLetterList[_rand.nextInt(_safeStartLetterList.length)];
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

  @visibleForTesting
  int get growSegmentsForTest => _growSegments;

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
    _moveTimer = null;
    _resetTimer = null;
  }

  @visibleForTesting
  Duration get moveDelayForTest => moveDelay;

  @visibleForTesting
  void clearGridLettersForTest() {
    for (var i = 0; i < _grid.length; i++) {
      final pos = _grid.positionOfIndex(i);
      _grid.placeLetter(pos, '');
    }
    _currentTiles = 0;
    gridNotifier.value++;
  }

  @visibleForTesting
  void setCurrentTilesForTest(int value) {
    _currentTiles = value;
  }

  @visibleForTesting
  void spawnRandomTilesForTest(int count) {
    _spawnRandomTiles(count);
    gridNotifier.value++;
  }

  @visibleForTesting
  int get currentTilesForTest => _currentTiles;

  @visibleForTesting
  int get minSpawnDistanceForTest => _minSpawnDistance;

  @visibleForTesting
  Set<String> get safeStartLettersForTest => _safeStartLetters;

  @visibleForTesting
  bool get isGameOverForTest => _isGameOver;

  @visibleForTesting
  int get livesForTest => _lives;
}