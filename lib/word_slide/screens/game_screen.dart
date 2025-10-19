//Y:\word_game_app_puzzle\lib\screens\game_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/cosmetic_manager.dart';
import 'package:word_game_app/services/game_feedback_service.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/utils/pause_manager.dart';
import 'package:word_game_app/word_slide/controllers/word_quest_controller.dart';
import 'package:word_game_app/word_slide/models/board_style.dart';
import 'package:word_game_app/word_slide/widgets/tap_feedback_overlay.dart';
import 'package:word_game_app/word_slide/widgets/tile.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.onPauseToggle,
    required this.onRewardedAdRequest,
    required this.adUsesThisMatch,
    required this.maxAdUsesPerMatch,
  });

  final VoidCallback onPauseToggle;
  final VoidCallback onRewardedAdRequest;
  final int adUsesThisMatch;
  final int maxAdUsesPerMatch;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _hintButtonController;
  late final Animation<double> _hintButtonAnimation;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _hintButtonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _hintButtonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hintButtonController, curve: Curves.easeInOut),
    );
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
  }

  @override
  void dispose() {
    _hintButtonController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Color _resolveTileColor(Color fallback, String skin) {
    switch (skin) {
      case 'wood':
        return const Color(0xFF8D6E63);
      case 'neon':
        return const Color(0xFF00F5D4);
      case 'crystal':
        return const Color(0xFF80DEEA);
      default:
        return fallback;
    }
  }

  BoxDecoration _resolveBoardDecoration(
      BoardStyleDecoration base,
      CosmeticManager cosmetics,
      ) {
    Gradient? gradient = base.backgroundGradient;
    Color? backgroundColor = base.backgroundColor;

    switch (cosmetics.boardSkin) {
      case 'galaxy':
        gradient = const LinearGradient(
          colors: [
            Color(0xFF1B2735),
            Color(0xFF090A0F),
            Color(0xFF3A1C71),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        backgroundColor = null;
        break;
      case 'cyber':
        gradient = const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        backgroundColor = null;
        break;
      case 'classic':
      default:
        break;
    }

    return BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      borderRadius: base.borderRadius,
      border: base.border,
      boxShadow: base.boxShadows,
      image: base.backgroundImage,
    );
  }

  Widget _buildHeader(WordQuestController controller) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: controller.moves,
              builder: (context, moves, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  'Moves: $moves',
                  key: ValueKey<int>(moves),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<int>(
              valueListenable: controller.hintsRemaining,
              builder: (context, hints, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  'Hints: $hints',
                  key: ValueKey<int>(hints),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Pause',
              onPressed: widget.onPauseToggle,
              icon: const Icon(Icons.pause_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WordQuestController>();
    final settings = context.watch<SettingsService>();
    final cosmetics = context.watch<CosmeticManager>();
    final pauseManager = context.watch<PauseManager>();

    GameFeedbackService.configure(
      soundEnabled: settings.soundEnabled,
      hapticsEnabled: settings.hapticsEnabled,
      soundPack: cosmetics.soundPack,
    );

    final boardStyleDecoration = settings.boardStyle
        .buildDecoration(BoardStyleContext(theme: Theme.of(context)));
    final boardBoxDecoration =
    _resolveBoardDecoration(boardStyleDecoration, cosmetics);
    final tileColor = _resolveTileColor(settings.tileColor, cosmetics.tileSkin);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: controller.hintsRemaining,
        builder: (context, hints, _) {
          final canUseHint = hints > 0;
          final canUseAd =
              widget.adUsesThisMatch < widget.maxAdUsesPerMatch;
          final String label;
          Icon icon;
          if (canUseHint) {
            label = 'Hint ($hints)';
            icon = const Icon(Icons.lightbulb_outline);
          } else if (canUseAd) {
            label = 'Get +3 Hints';
            icon = const Icon(Icons.play_circle);
          } else {
            label = 'No more hints';
            icon = const Icon(Icons.block);
          }

          return ScaleTransition(
            scale:
            canUseHint ? _hintButtonAnimation : const AlwaysStoppedAnimation(1.0),
            child: FloatingActionButton.extended(
              heroTag: 'hintButton',
              onPressed: (!canUseHint && !canUseAd)
                  ? null
                  : () {
                if (canUseHint) {
                  controller.showHint();
                } else {
                  widget.onRewardedAdRequest();
                }
              },
              label: Text(label),
              icon: icon,
              backgroundColor: canUseHint ? Colors.amber : Colors.grey,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: TouchFeedbackOverlay(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight =
              max(260.0, constraints.maxHeight - 140.0);
              final boardSize =
              min(constraints.maxWidth, availableHeight);

              return Column(
                children: [
                  _buildHeader(controller),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: Hero(
                          tag: 'word-quest-board',
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _introController,
                              curve: Curves.easeOut,
                            ),
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: _introController,
                                curve: Curves.easeOutBack,
                              ),
                              child: Container(
                                decoration: boardBoxDecoration,
                                child: ClipRRect(
                                  borderRadius:
                                  boardStyleDecoration.borderRadius,
                                  child: Padding(
                                    padding: boardStyleDecoration.padding,
                                    child: LayoutBuilder(
                                      builder: (context, boardConstraints) {
                                        final cellSize =
                                            boardConstraints.maxWidth / 4;
                                        return Stack(
                                          children: [
                                            GridView.builder(
                                              physics:
                                              const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.zero,
                                              itemCount: controller.tiles.length,
                                              gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                              ),
                                              itemBuilder: (context, index) {
                                                return ValueListenableBuilder<
                                                    TileVisualState>(
                                                  valueListenable:
                                                  controller.tiles[index],
                                                  builder:
                                                      (context, tile, __) {
                                                    final displayLetter =
                                                    settings.useTitleCaseWords
                                                        ? tile.letter
                                                        : tile.letter
                                                        .toUpperCase();
                                                    return IgnorePointer(
                                                      ignoring:
                                                      pauseManager.isPaused,
                                                      child: TileWidget(
                                                        key:
                                                        ValueKey<int>(index),
                                                        letter: displayLetter,
                                                        onTap: () =>
                                                            controller
                                                                .onTileTapped(
                                                                index),
                                                        highlighted:
                                                        tile.highlighted,
                                                        disappearing:
                                                        tile.disappearing,
                                                        highlightKind:
                                                        tile.highlightKind,
                                                        tileColor: tile.letter
                                                            .trim()
                                                            .isEmpty
                                                            ? Colors
                                                            .transparent
                                                            : tileColor,
                                                        borderColor:
                                                        settings.borderColor,
                                                        borderStyle:
                                                        settings.borderStyle,
                                                        animationStyle: settings
                                                            .tileAnimationStyle,
                                                        hintEffect:
                                                        cosmetics.hintEffect,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            ValueListenableBuilder<int>(
                                              valueListenable:
                                              controller.pulseTicker,
                                              builder:
                                                  (context, tick, __) {
                                                if (tick == 0) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                return TweenAnimationBuilder<
                                                    double>(
                                                  key: ValueKey<int>(tick),
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ),
                                                  duration: const Duration(
                                                      milliseconds: 420),
                                                  builder:
                                                      (context, value, _) {
                                                    final opacity =
                                                    (1 - value)
                                                        .clamp(0.0, 1.0);
                                                    return IgnorePointer(
                                                      child: Opacity(
                                                        opacity: opacity,
                                                        child:
                                                        DecoratedBox(
                                                          decoration:
                                                          BoxDecoration(
                                                            borderRadius:
                                                            boardStyleDecoration
                                                                .borderRadius,
                                                            border: Border.all(
                                                              color: Colors
                                                                  .amberAccent
                                                                  .withOpacity(
                                                                  opacity),
                                                              width: 8 *
                                                                  (1 - value),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            ValueListenableBuilder<ScorePopup?>(
                                              valueListenable:
                                              controller.scorePopup,
                                              builder:
                                                  (context, popup, __) {
                                                if (popup == null) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                final left = popup.gridX *
                                                    cellSize +
                                                    (cellSize / 2) -
                                                    16;
                                                final top = popup.gridY *
                                                    cellSize +
                                                    (cellSize / 2) -
                                                    16;
                                                return Positioned(
                                                  left: left,
                                                  top: top,
                                                  child:
                                                  TweenAnimationBuilder<
                                                      double>(
                                                    key: ValueKey<int>(
                                                        controller
                                                            .pulseTicker
                                                            .value),
                                                    tween: Tween(
                                                      begin: 0,
                                                      end: -24,
                                                    ),
                                                    duration:
                                                    const Duration(
                                                        milliseconds:
                                                        520),
                                                    onEnd: () => controller
                                                        .scorePopup.value =
                                                    null,
                                                    builder: (context, dy,
                                                        child) {
                                                      final opacity = 1.0 -
                                                          (dy.abs() / 24.0)
                                                              .clamp(0.0, 1.0);
                                                      return Opacity(
                                                        opacity: opacity,
                                                        child:
                                                        Transform.translate(
                                                          offset:
                                                          Offset(0, dy),
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      popup.isWord
                                                          ? '+${popup.points}!'
                                                          : '+${popup.points}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                        fontWeight:
                                                        FontWeight
                                                            .w800,
                                                        shadows: const [
                                                          Shadow(
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}




  //late SoundManager soundManager = SoundManager();


















