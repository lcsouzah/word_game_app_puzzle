import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_controller.dart';
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
  final SerpuzzleGameController controller;
  final int gridSize;
  final List<String> dictionary;
  final int maxWordLength;
  final bool startCentered;
  final Duration moveDelay;

  final bool wrapAround;

  const SerpuzzleGameScreen({
    super.key,
    required this.controller,
    required this.gridSize,
    required this.dictionary,
    required this.maxWordLength,
    this.startCentered = true,
    this.moveDelay = const Duration(milliseconds: 300),

    this.wrapAround = false,


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
  late WordMatchEngine _engine;
  Timer? _resetTimer;
  late Duration _moveDelay;
  late int _maxWordLength;
  Timer? _moveTimer;
  Direction _currentDirection = Direction.right;
  int _growSegments = 0;
  late List<String> _letterPool;
  int _currentTiles = 0;
  bool _isGameOver = false;

  int get _tilesNeeded => max(0, 4 - _currentTiles);

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _maxWordLength = widget.maxWordLength;
    _letterPool = widget.dictionary
        .expand((w) => w.toUpperCase().split(''))
        .toList();
    _moveDelay = widget.moveDelay;
    _isPaused = widget.controller.isPaused;
    widget.controller.addListener(_handleControllerChanged);
    widget.controller.onTimeExpired ??= _handleTimeExpired;
    _initBoard();
    if (!_isPaused) {
      _startMoveTimer();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _moveTimer?.cancel();
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(_moveDelay, (_) => _tick());
  }

  void _handleControllerChanged() {
    final controller = widget.controller;
    if (_isPaused != controller.isPaused) {
      setState(() {
        _isPaused = controller.isPaused;
        if (_isPaused) {
          _moveTimer?.cancel();
          _moveTimer = null;
        } else {
          _startMoveTimer();
        }
      });
    }
    if (_isGameOver != controller.isGameOver) {
      setState(() {
        _isGameOver = controller.isGameOver;
        if (_isGameOver) {
          _moveTimer?.cancel();
        }
      });
    }
  }

  void _handleTimeExpired() {
    if (_isGameOver) {
      return;
    }
    _gameOver();
  }

  void _initBoard() {
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
      _isMatched = false;
      _initBoard();
      _isGameOver = false;
    });
    widget.controller.resetForNewGame(startTimer: !_isPaused);
    _startMoveTimer();
  }

  void _handleCollision() {
    _resetTimer?.cancel();
    if (!widget.controller.consumeLife()) {
      _gameOver();
      return;
    }
    setState(() {
      _isMatched = false;
      _initBoard();
    });
  }

  Future<void> _gameOver() async {
    if (_isGameOver) return;
    _isGameOver = true;
    _moveTimer?.cancel();
    widget.controller.markGameOver();
    final finalScore = widget.controller.score;
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
      if (!widget.controller.consumeLife()) {
        _handleCollision();
        return;
      }
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
      if (letter.isNotEmpty) {
        _snake.transferHeadLetterToPrevious();
      }

      if (_growSegments > 0) {
        _growSegments--;
      } else if (_snake.segments.length > 1) {
        _snake.dropFirstBlankSegment();
      }
      while (_snake.word.length > _maxWordLength &&
          _snake.segments.length > 1) {
        _snake.clearRange(0, 1);
      }
      _snake.alignLettersBehindHead();
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
        _isMatched = true;
      });
      widget.controller.addScore(letters.length);
      widget.controller.advanceLevel();
      _showLevelTransition();
    }
  }

  Future<void> _showLevelTransition() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PortalAnimation(level: widget.controller.level),
    );
    if (!mounted) return;
    setState(() {
      _isMatched = false;
      _initBoard();
    });
    widget.controller.startLevelTimer(resetElapsed: true);
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
    const boardPadding = EdgeInsets.all(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? max(0.0, constraints.maxWidth - boardPadding.horizontal)
            : double.infinity;
        final availableHeight = constraints.maxHeight.isFinite
            ? max(0.0, constraints.maxHeight - boardPadding.vertical)
            : double.infinity;

        double boardExtent;
        if (availableWidth.isFinite && availableHeight.isFinite) {
          boardExtent = min(availableWidth, availableHeight);
        } else if (availableWidth.isFinite) {
          boardExtent = availableWidth;
        } else if (availableHeight.isFinite) {
          boardExtent = availableHeight;
        } else {
          boardExtent = 320;
        }
        boardExtent = max(0.0, boardExtent);

        if (boardExtent == 0) {
          return const SizedBox.shrink();
        }

        final boardRadius = BorderRadius.circular(14);
        final currentWord = _snake.word;
        final hasLetters = currentWord.isNotEmpty;
        final bannerText = hasLetters ? currentWord : 'Collect letters';
        final celebrating = _isMatched && hasLetters;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: boardRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface.withOpacity(0.75),
                      theme.colorScheme.surfaceVariant.withOpacity(0.55),
                    ],
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.55),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                padding: boardPadding,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.35),
                    ),
                  ),
                  child: SwipeDetector(
                    onSwipe: _onSwipe,
                    child: SizedBox.square(
                      dimension: boardExtent,
                      child: _SerpuzzleBoard(
                        boardExtent: boardExtent,
                        grid: _grid,
                        snake: _snake,
                        isMatched: _isMatched,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedScale(
                key: const ValueKey('word-banner-scale'),
                scale: celebrating ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: celebrating ? Curves.easeOutBack : Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  opacity: celebrating ? 1.0 : 0.9,
                  child: AnimatedContainer(
                    key: const ValueKey('current-word-banner'),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 28,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: celebrating
                            ? [
                          theme.colorScheme.primary.withOpacity(0.95),
                          theme.colorScheme.secondary.withOpacity(0.85),
                        ]
                            : [
                          theme.colorScheme.surface.withOpacity(0.78),
                          theme.colorScheme.surfaceVariant.withOpacity(0.56),
                        ],
                      ),
                      border: Border.all(
                        color: celebrating
                            ? theme.colorScheme.onPrimary.withOpacity(0.4)
                            : theme.colorScheme.onSurface.withOpacity(0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (celebrating
                              ? theme.colorScheme.primary
                              : Colors.black)
                              .withOpacity(celebrating ? 0.35 : 0.18),
                          blurRadius: celebrating ? 26 : 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Text(
                        bannerText,
                        key: ValueKey<String>(bannerText),
                        textAlign: TextAlign.center,
                        style: (theme.textTheme.headlineSmall ??
                            const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ))
                            .copyWith(
                          letterSpacing: 1.2,
                          color: celebrating
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  }

  @visibleForTesting
  Duration get moveDelayForTest => _moveDelay;

  @visibleForTesting
  Duration get elapsedForTest => widget.controller.elapsed;

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
  int get livesForTest => widget.controller.lives;

}

class _SerpuzzleBoard extends StatelessWidget {
  const _SerpuzzleBoard({
    required this.boardExtent,
    required this.grid,
    required this.snake,
    required this.isMatched,
  });

  final double boardExtent;
  final SerpuzzleGrid grid;
  final SerpuzzleSnake snake;
  final bool isMatched;

  @override
  Widget build(BuildContext context) {
    final tileSize = boardExtent / grid.cols;
    const segmentScale = 0.4;
    final snakePositions = snake.segments.toSet();
    final letters = snake.letters;
    final segments = <SnakeSegment>[];
    for (var i = 0; i < snake.segments.length; i++) {
      final pos = snake.segments[i];
      final isHead = i == snake.segments.length - 1;
      segments.add(
        SnakeSegment(
          row: pos.row,
          col: pos.col,
          letter: isHead ? '' : letters[i],
          highlighted: isMatched,
        ),
      );
    }

    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.55),
              theme.colorScheme.surfaceVariant.withOpacity(0.35),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SerpuzzleBoardBackdropPainter(
                rows: grid.rows,
                cols: grid.cols,
                fineDivisions: 2,
                lightColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.18),
                darkColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.1),
                gridLineColor: theme.colorScheme.outline.withOpacity(0.12),
              ),
            ),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: grid.cols,
                childAspectRatio: 1,
              ),
              itemCount: grid.length,
              itemBuilder: (context, index) {
                final pos = grid.positionOfIndex(index);
                final isSnake = snakePositions.contains(pos);
                final highlight = isMatched && isSnake;
                return SerpuzzleTile(
                  letter: isSnake ? '' : grid.letterAt(pos),
                  highlighted: highlight,
                );
              },
            ),
            SerpuzzleSnakeBody(
              segments: segments,
              tileSize: tileSize,
              segmentScale: segmentScale,
            ),
          ],
        ),
      ),
    );
  }
}

typedef SerpuzzleGameScreenState = _SerpuzzleGameScreenState;

class _SerpuzzleBoardBackdropPainter extends CustomPainter {
  final int rows;
  final int cols;
  final int fineDivisions;
  final Color lightColor;
  final Color darkColor;
  final Color gridLineColor;

  const _SerpuzzleBoardBackdropPainter({
    required this.rows,
    required this.cols,
    required this.fineDivisions,
    required this.lightColor,
    required this.darkColor,
    required this.gridLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fineRows = max(1, rows * fineDivisions);
    final fineCols = max(1, cols * fineDivisions);
    final cellWidth = size.width / fineCols;
    final cellHeight = size.height / fineRows;

    final rect = Rect.fromLTWH(0, 0, cellWidth, cellHeight);
    final paint = Paint();
    for (var row = 0; row < fineRows; row++) {
      for (var col = 0; col < fineCols; col++) {
        final offset = Offset(col * cellWidth, row * cellHeight);
        final isLight = (row + col) % 2 == 0;
        paint.color = isLight ? lightColor : darkColor;
        canvas.drawRect(rect.shift(offset), paint);
      }
    }

    final linePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0;

    for (var r = 0; r <= fineRows; r++) {
      final dy = r * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }

    for (var c = 0; c <= fineCols; c++) {
      final dx = c * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SerpuzzleBoardBackdropPainter oldDelegate) {
    return rows != oldDelegate.rows ||
        cols != oldDelegate.cols ||
        fineDivisions != oldDelegate.fineDivisions ||
        lightColor != oldDelegate.lightColor ||
        darkColor != oldDelegate.darkColor ||
        gridLineColor != oldDelegate.gridLineColor;
  }
}