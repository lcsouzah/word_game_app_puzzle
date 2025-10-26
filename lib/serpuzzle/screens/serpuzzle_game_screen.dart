import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_grid.dart';
import 'package:word_game_app/serpuzzle/models/serpuzzle_snake.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_controller.dart';
import 'package:word_game_app/serpuzzle/serpuzzle_tunables.dart';
import 'package:word_game_app/serpuzzle/widgets/portal_animation.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_body.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_snake_head.dart';
import 'package:word_game_app/serpuzzle/widgets/serpuzzle_tile.dart';
import 'package:word_game_app/utils/direction_enum.dart';
import 'package:word_game_app/utils/swipe_detector.dart';

/// Serpuzzle game screen showing the grid and handling swipe input.
class SerpuzzleGameScreen extends StatefulWidget {
  const SerpuzzleGameScreen({
    super.key,
    required this.controller,
  });

  final SerpuzzleGameController controller;

  @override
  State<SerpuzzleGameScreen> createState() => _SerpuzzleGameScreenState();
}

class _SerpuzzleGameScreenState extends State<SerpuzzleGameScreen>
    with TickerProviderStateMixin {
  final GlobalKey<PortalAnimationState> _portalKey =
  PortalAnimation.createKey();
  Listenable? _boardListenable;
  bool _handlingMatch = false;
  bool _handlingGameOver = false;
  late final AnimationController _shakeController;
  late final Ticker _frameTicker;
  final GlobalKey<SerpuzzleSnakeHeadState> _headKey =
  GlobalKey<SerpuzzleSnakeHeadState>();
  final List<_BoardOverlayEntry> _floatingIndicators = [];
  int _damageEventId = 0;
  int _rewardEventId = 0;
  bool _inputLocked = false;
  Offset? _lastHeadPixel;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: impactShakeDuration,
    );
    _frameTicker = createTicker(_onFrame)..start();
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant SerpuzzleGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    _frameTicker.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _attachController(SerpuzzleGameController controller) {
    _boardListenable = Listenable.merge([
      controller.gridListenable,
      controller.snakeListenable,
      controller.isMatchedListenable,
      controller.justEatenCell,
      controller.headProgressListenable,
    ]);
    _damageEventId = controller.damageListenable.value;
    _rewardEventId = controller.rewardListenable.value;
    controller.isMatchedListenable.addListener(_handleMatchChanged);
    controller.isGameOverListenable.addListener(_handleGameOverChanged);
    controller.damageListenable.addListener(_handleDamageEvent);
    controller.rewardListenable.addListener(_handleRewardEvent);
  }

  void _detachController(SerpuzzleGameController controller) {
    controller.isMatchedListenable.removeListener(_handleMatchChanged);
    controller.isGameOverListenable.removeListener(_handleGameOverChanged);
    controller.damageListenable.removeListener(_handleDamageEvent);
    controller.rewardListenable.removeListener(_handleRewardEvent);
    _boardListenable = null;
  }

  void _handleMatchChanged() {
    if (!mounted || _handlingMatch) return;
    if (!widget.controller.isMatched) return;
    _handlingMatch = true;
    Future.microtask(() async {
      await _showLevelTransition();
      if (!mounted) return;
      widget.controller.prepareNextLevel();
      _handlingMatch = false;
    });
  }

  void _handleGameOverChanged() {
    if (!mounted || _handlingGameOver) return;
    if (!widget.controller.isGameOver) return;
    _handlingGameOver = true;
    Future.microtask(() async {
      await _showGameOverDialog();
      if (!mounted) return;
      widget.controller.resetForNewGame(startTimer: !widget.controller.isPaused);
      _handlingGameOver = false;
    });
  }

  void _onFrame(Duration elapsed) {
    widget.controller.handleFrame(elapsed);
  }

  void _handleDamageEvent() {
    if (!mounted) return;
    final value = widget.controller.damageListenable.value;
    if (value == _damageEventId) {
      return;
    }
    _damageEventId = value;
    if (value == 0) {
      return;
    }
    _triggerDamageFeedback();
  }

  void _handleRewardEvent() {
    if (!mounted) return;
    final value = widget.controller.rewardListenable.value;
    if (value == _rewardEventId) {
      return;
    }
    _rewardEventId = value;
    if (value == 0) {
      return;
    }
    _triggerRewardFeedback();
  }

  void _triggerDamageFeedback() {
    final head = _lastHeadPixel;
    if (head != null) {
      _showDamageIndicatorAt(head);
    }
    _shakeController
      ..stop()
      ..reset()
      ..forward();
    if (widget.controller.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  void _triggerRewardFeedback() {
    _headKey.currentState?.pulse();
    final head = _lastHeadPixel;
    if (head != null) {
      final popup = widget.controller.scorePopup.value;
      final text = popup != null ? '+${popup.points}' : '+1';
      _showPointsIndicatorAt(head, text);
    }
    if (widget.controller.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _addOverlayWidget(Widget child, Duration lifespan) {
    if (!mounted) return;
    final key = UniqueKey();
    final entry = _BoardOverlayEntry(
      key: key,
      child: KeyedSubtree(key: key, child: child),
    );
    setState(() {
      _floatingIndicators.add(entry);
    });
    Future.delayed(lifespan, () {
      if (!mounted) return;
      setState(() {
        _floatingIndicators.removeWhere((element) => element.key == key);
      });
    });
  }

  void _showDamageIndicatorAt(Offset position) {
    _addOverlayWidget(DamageIndicator(position: position), damageIndicatorDuration);
  }

  void _showPointsIndicatorAt(Offset position, String text) {
    _addOverlayWidget(PointsIndicator(position: position, text: text), pointsFloatDuration);
  }

  Offset _computeShakeOffset() {
    if (!_shakeController.isAnimating) {
      return Offset.zero;
    }
    final progress = _shakeController.value;
    final decay = 1 - Curves.easeOutQuad.transform(progress);
    final dx = sin(progress * pi * 8) * impactShakeAmplitude * decay;
    final dy = cos(progress * pi * 6) * (impactShakeAmplitude * 0.45) * decay;
    return Offset(dx, dy);
  }

  Future<void> _showGameOverDialog() async {
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
  }

  Future<void> _showLevelTransition() async {
    setState(() {
      _inputLocked = true;
      _floatingIndicators.clear();
    });
    final dialogFuture = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PortalAnimation(
        key: _portalKey,
        level: widget.controller.level,
        onStarted: widget.controller.clearInputQueue,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portalKey.currentState?.play();
    });
    await dialogFuture;
    if (!mounted) return;
    setState(() {
      _inputLocked = false;
    });
  }

  void _onSwipe(Direction direction) {
    widget.controller.queueDirection(direction);
  }

  @override
  Widget build(BuildContext context) {
    const boardPadding = EdgeInsets.all(16);
    final listenable = _boardListenable ?? widget.controller.snakeListenable;
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

        return AnimatedBuilder(
          animation: listenable,
          builder: (context, _) {
            final snake = widget.controller.snake;
            final grid = widget.controller.grid;
            final currentWord = snake.word;
            final hasLetters = currentWord.isNotEmpty;
            final bannerText = hasLetters ? currentWord : 'Collect letters';
            final celebrating = widget.controller.isMatched && hasLetters;
            final boardRadius = BorderRadius.circular(14);
            final headCurrentCell = widget.controller.currentHeadCellCenter;
            final headNextCell = widget.controller.nextHeadCellCenter;
            final headProgress = widget.controller.headProgress;
            final tileSize = grid.cols == 0 ? 0.0 : boardExtent / grid.cols;
            if (tileSize > 0) {
              final headCurrentPixel = Offset(
                headCurrentCell.dx * tileSize,
                headCurrentCell.dy * tileSize,
              );
              final headNextPixel = Offset(
                headNextCell.dx * tileSize,
                headNextCell.dy * tileSize,
              );
              _lastHeadPixel = Offset.lerp(headCurrentPixel, headNextPixel, headProgress) ??
                  headCurrentPixel;
            }

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
                        color:
                        theme.colorScheme.outlineVariant.withOpacity(0.55),
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
                          color: theme.colorScheme.outlineVariant
                              .withOpacity(0.35),
                        ),
                      ),
                      child: IgnorePointer(
                        ignoring: _inputLocked,
                        child: SwipeDetector(
                          onSwipe: _onSwipe,
                          child: AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              final offset = _computeShakeOffset();
                              return Transform.translate(
                                offset: offset,
                                child: child,
                              );
                            },
                            child: SizedBox.square(
                              dimension: boardExtent,
                              child: _SerpuzzleBoard(
                                boardExtent: boardExtent,
                                grid: grid,
                                snake: snake,
                                isMatched: widget.controller.isMatched,
                                controller: widget.controller,
                                headKey: _headKey,
                                headCurrentCell: headCurrentCell,
                                headNextCell: headNextCell,
                                headProgress: headProgress,
                                overlayIndicators: _floatingIndicators
                                    .map((entry) => entry.child)
                                    .toList(growable: false),
                              ),
                            ),
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
                    curve:
                    celebrating ? Curves.easeOutBack : Curves.easeOutCubic,
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
                              theme.colorScheme.primary
                                  .withOpacity(0.95),
                              theme.colorScheme.secondary
                                  .withOpacity(0.85),
                            ]
                                : [
                              theme.colorScheme.surface.withOpacity(0.78),
                              theme.colorScheme.surfaceVariant
                                  .withOpacity(0.56),
                            ],
                          ),
                          border: Border.all(
                            color: celebrating
                                ? theme.colorScheme.onPrimary.withOpacity(0.4)
                                : theme.colorScheme.onSurface
                                .withOpacity(0.12),
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
      },
    );
  }

  @visibleForTesting
  SerpuzzleSnake get snake => widget.controller.snake;

  @visibleForTesting
  SerpuzzleGrid get grid => widget.controller.grid;

  @visibleForTesting
  int get growSegments => widget.controller.growSegmentsForTest;

  @visibleForTesting
  void setGrowSegmentsForTest(int value) =>
      widget.controller.setGrowSegmentsForTest(value);

  @visibleForTesting
  void setDirectionForTest(Direction direction) =>
      widget.controller.setDirectionForTest(direction);

  @visibleForTesting
  void tickForTest() => widget.controller.tickForTest();

  @visibleForTesting
  void cancelTimersForTest() {
    _frameTicker.stop();
    widget.controller.cancelTimersForTest();
  }

  @visibleForTesting
  Duration get moveDelayForTest => widget.controller.moveDelayForTest;

  @visibleForTesting
  Duration get elapsedForTest => widget.controller.elapsed;

  @visibleForTesting
  void clearGridLettersForTest() => widget.controller.clearGridLettersForTest();

  @visibleForTesting
  void setCurrentTilesForTest(int value) =>
      widget.controller.setCurrentTilesForTest(value);

  @visibleForTesting
  void spawnRandomTilesForTest(int count) =>
      widget.controller.spawnRandomTilesForTest(count);

  @visibleForTesting
  int get currentTilesForTest => widget.controller.currentTilesForTest;

  @visibleForTesting
  int get minSpawnDistanceForTest => widget.controller.minSpawnDistanceForTest;

  @visibleForTesting
  Set<String> get safeStartLettersForTest =>
      widget.controller.safeStartLettersForTest;

  @visibleForTesting
  bool get isGameOverForTest => widget.controller.isGameOverForTest;

  @visibleForTesting
  int get livesForTest => widget.controller.livesForTest;
}

class _BoardOverlayEntry {
  const _BoardOverlayEntry({required this.key, required this.child});

  final Key key;
  final Widget child;
}

class DamageIndicator extends StatelessWidget {
  const DamageIndicator({super.key, required this.position});

  final Offset position;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: damageIndicatorDuration,
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        final fade = (1 - value).clamp(0.0, 1.0);
        return Positioned(
          left: position.dx - 10,
          top: position.dy - 20 - (value * 18),
          child: Opacity(
            opacity: fade,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite, size: 20, color: Colors.redAccent),
                SizedBox(width: 2),
                Icon(Icons.remove, size: 18, color: Colors.redAccent),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PointsIndicator extends StatelessWidget {
  const PointsIndicator({super.key, required this.position, required this.text});

  final Offset position;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.titleSmall ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: pointsFloatDuration,
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        final opacity = (1 - Curves.easeInQuad.transform(value)).clamp(0.0, 1.0);
        return Positioned(
          left: position.dx - 14,
          top: position.dy - 28 - (value * 20),
          child: Opacity(
            opacity: opacity,
            child: Text(
              text,
              style: baseStyle.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SerpuzzleBoard extends StatelessWidget {
  const _SerpuzzleBoard({
    required this.boardExtent,
    required this.grid,
    required this.snake,
    required this.isMatched,
    required this.controller,
    required this.headKey,
    required this.headCurrentCell,
    required this.headNextCell,
    required this.headProgress,
    required this.overlayIndicators,
  });

  final double boardExtent;
  final SerpuzzleGrid grid;
  final SerpuzzleSnake snake;
  final bool isMatched;
  final SerpuzzleGameController controller;
  final GlobalKey<SerpuzzleSnakeHeadState> headKey;
  final Offset headCurrentCell;
  final Offset headNextCell;
  final double headProgress;
  final List<Widget> overlayIndicators;


  @override
  Widget build(BuildContext context) {
    if (grid.cols == 0) {
      return const SizedBox.shrink();
    }
    final tileSize = boardExtent / grid.cols;
    final snakePositions = snake.segments.toSet();
    final justEatenCell = controller.justEatenCell.value;
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

    final headCurrentPixel = Offset(
      headCurrentCell.dx * tileSize,
      headCurrentCell.dy * tileSize,
    );
    final headNextPixel = Offset(
      headNextCell.dx * tileSize,
      headNextCell.dy * tileSize,
    );
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
        child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _SerpuzzleBoardBackdropPainter(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.surfaceVariant.withOpacity(0.28),
                        theme.colorScheme.surface.withOpacity(0.4),
                        theme.colorScheme.surfaceVariant.withOpacity(0.18),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    fallbackColor:
                    theme.colorScheme.surfaceVariant.withOpacity(0.24),
                  ),
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
                  final justEaten = justEatenCell != null && justEatenCell == pos;
                  return SerpuzzleTile(
                    letter: isSnake ? '' : grid.letterAt(pos),
                    highlighted: highlight,
                    justEaten: justEaten,
                  );
                },
              ),
              SerpuzzleSnakeBody(
                segments: segments,
                tileSize: tileSize,
                headKey: headKey,
                headCurrentPixel: headCurrentPixel,
                headNextPixel: headNextPixel,
                headProgress: headProgress,
              ),
              ...overlayIndicators,
              ValueListenableBuilder<Object?>(
                valueListenable: controller.scorePopup,
                builder: (context, value, _) {
                  if (value == null) {
                    return const SizedBox.shrink();
                  }
                  final popup = value as dynamic;
                  final left = (popup.gridX as num) * tileSize;
                  final top = (popup.gridY as num) * tileSize;
                  final isWord = popup.isWord == true;
                  final textColor = isWord
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface;
                  final backgroundColor = isWord
                      ? theme.colorScheme.primary.withOpacity(0.35)
                      : theme.colorScheme.surface.withOpacity(0.65);
                  final borderColor = isWord
                      ? theme.colorScheme.onPrimary.withOpacity(0.45)
                      : theme.colorScheme.onSurface.withOpacity(0.2);
                  final shadowColor = (isWord
                      ? theme.colorScheme.primary
                      : Colors.black)
                      .withOpacity(isWord ? 0.3 : 0.18);

                  return Positioned(
                    left: left,
                    top: top,
                    width: tileSize,
                    height: tileSize,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<Object>(popup),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: pointsFloatDuration,
                      curve: Curves.easeOutCubic,
                      onEnd: () {
                        if (identical(controller.scorePopup.value, popup)) {
                          controller.scorePopup.value = null;
                        }
                      },
                      builder: (context, progress, child) {
                        final eased = Curves.easeOut.transform(progress);
                        final slide = lerpDouble(
                          0,
                          -tileSize * 0.75,
                          eased,
                        ) ??
                            0;
                        final clamped = progress.clamp(0.0, 1.0).toDouble();
                        final opacity =
                            1 - Curves.easeInQuad.transform(clamped);
                        return Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, slide),
                            child: child,
                          ),
                        );
                      },
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 1.1),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Text(
                              '+${popup.points}',
                              textAlign: TextAlign.center,
                              style: (theme.textTheme.titleSmall ??
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ))
                                  .copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef SerpuzzleGameScreenState = _SerpuzzleGameScreenState;

class _SerpuzzleBoardBackdropPainter extends CustomPainter {
  final Gradient? gradient;
  final Color fallbackColor;

  const _SerpuzzleBoardBackdropPainter({
    this.gradient,
    required this.fallbackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = fallbackColor;
    }
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SerpuzzleBoardBackdropPainter oldDelegate) {
    return gradient != oldDelegate.gradient ||
        fallbackColor != oldDelegate.fallbackColor;
  }
}