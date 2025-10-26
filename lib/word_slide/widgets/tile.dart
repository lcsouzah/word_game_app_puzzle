//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/models/tile_highlight_kind.dart';

class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted; // 🔴 highlighted on hint logic
  final bool disappearing; // 🔴 disappearing correct word animation
  final Color tileColor;
  final Color borderColor;
  final TileBorderStyle borderStyle;
  final TileAnimationStyle animationStyle;
  final TileHighlightKind? highlightKind;
  final String hintEffect;
  final bool idleShimmerEnabled;


  TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
    this.disappearing = false,
    this.highlightKind = TileHighlightKind.none,
    this.hintEffect = 'ring',
    this.idleShimmerEnabled = true,
    Color tileColor = Colors.blueGrey,
    Color? borderColor,
    TileBorderStyle? borderStyle,
    TileAnimationStyle? animationStyle,
  })  : tileColor = tileColor,
        borderColor = borderColor ?? tileColor,
        borderStyle = borderStyle ?? TileBorderStyles.none,
        animationStyle = animationStyle ?? TileAnimationStyles.defaultStyle;


  @override
  TileWidgetState createState() => TileWidgetState();

}

class TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _idleController;
  Animation<double>? _idleOpacity;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: _resolveIdleDuration(widget.animationStyle),
    );
    _refreshIdleAnimation(restart: true);
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final styleChanged =
        oldWidget.animationStyle.id != widget.animationStyle.id ||
            oldWidget.animationStyle.behavior !=
                widget.animationStyle.behavior ||
            oldWidget.animationStyle.idleLoopPeriod !=
                widget.animationStyle.idleLoopPeriod ||
            oldWidget.animationStyle.idleOpacityLowerBound !=
                widget.animationStyle.idleOpacityLowerBound;

    if (styleChanged) {
      _idleController.duration =
          _resolveIdleDuration(widget.animationStyle);
    }

    if (styleChanged ||
        oldWidget.letter != widget.letter ||
        oldWidget.idleShimmerEnabled != widget.idleShimmerEnabled) {
      _refreshIdleAnimation(restart: styleChanged);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  Duration _resolveIdleDuration(TileAnimationStyle style) {
    return style.idleLoopPeriod ?? const Duration(milliseconds: 1500);
  }

  double _resolveIdleLowerBound(TileAnimationStyle style) {
    final lower = style.idleOpacityLowerBound ?? 0.5;
    return lower.clamp(0.0, 1.0);
  }

  void _refreshIdleAnimation({bool restart = false}) {
    if (!widget.idleShimmerEnabled) {
      if (_idleController.isAnimating) {
        _idleController.stop();
      }
      _idleOpacity = null;
      return;
    }
    final shouldAnimateBlink =
        widget.animationStyle.behavior == TileAnimationBehavior.blink &&
            widget.letter.trim().isNotEmpty;

    if (shouldAnimateBlink) {
      final lowerBound =
      _resolveIdleLowerBound(widget.animationStyle);
      _idleOpacity = Tween<double>(
        begin: 1.0,
        end: lowerBound,
      ).animate(
        CurvedAnimation(
          parent: _idleController,
          curve: Curves.easeInOut,
        ),
      );
      if (restart || !_idleController.isAnimating) {
        _idleController.repeat(reverse: true);
      }
    } else {
      if (_idleController.isAnimating) {
        _idleController.stop();
      }
      _idleController.value = 0.0;
      _idleOpacity = null;
    }
  }

  void _onTapDown(_) {
    setState(() {
      _scale = 0.8; // slightly make tile smaller
    });
  }

  void _onTapUp(_) {
    setState(() {
      _scale = 1.1; // quick bounce out
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _scale = 1.0; // reset scale
        });
      }
    });
    widget.onTap(); // move tile
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0; // reset scale
    });
  }

  Widget _wrapWithIdleAnimation(Widget child) {
    final idleOpacity = _idleOpacity;
    if (idleOpacity == null) {
      return child;
    }
    return AnimatedBuilder(
      animation: idleOpacity,
      builder: (_, __) => Opacity(
        opacity: idleOpacity.value,
        child: child,
      ),
    );
  }

  Widget _applyActiveTransition(Widget child) {
    final style = widget.animationStyle;
    return AnimatedSwitcher(
      duration: style.transitionDuration,
      switchInCurve: style.switchInCurve,
      switchOutCurve: style.switchOutCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (animatedChild, animation) {
        switch (style.behavior) {
          case TileAnimationBehavior.slide:
            final position = animation.drive(
              Tween<Offset>(
                begin: const Offset(0.0, 0.18),
                end: Offset.zero,
              ),
            );
            return SlideTransition(
              position: position,
              child: FadeTransition(
                opacity: animation,
                child: animatedChild,
              ),
            );
          case TileAnimationBehavior.teleport:
            final fade = FadeTransition(
              opacity: animation,
              child: animatedChild,
            );
            final scaleAnimation = animation.drive(
              Tween<double>(begin: 0.9, end: 1.0),
            );
            return ScaleTransition(
              scale: scaleAnimation,
              child: fade,
            );
          case TileAnimationBehavior.blink:
            return FadeTransition(
              opacity: animation,
              child: animatedChild,
            );
          case TileAnimationBehavior.puff:
            final overshoot = style.puffScaleFactor ?? 1.1;
            final sequence = TweenSequence<double>([
              TweenSequenceItem<double>(
                tween: Tween<double>(
                  begin: 0.85,
                  end: overshoot,
                ).chain(CurveTween(curve: Curves.easeOut)),
                weight: 60,
              ),
              TweenSequenceItem<double>(
                tween: Tween<double>(
                  begin: overshoot,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeIn)),
                weight: 40,
              ),
            ]);
            final scale = animation.drive(sequence);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: scale,
                child: animatedChild,
              ),
            );
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.animationStyle;
    final isEmpty = widget.letter.trim().isEmpty;
    final decorationParts = widget.borderStyle.buildDecoration(
      tileColor: widget.tileColor,
      borderColor: widget.borderColor,
      highlighted: widget.highlighted,
    );
    final baseFillColor = decorationParts.fillColor ?? widget.tileColor;
    final bool isHintHighlight =
        widget.highlighted && widget.highlightKind == TileHighlightKind.hint;
    final bool isSolvedHighlight =
        widget.highlighted && widget.highlightKind == TileHighlightKind.solved;
    final bool useGradient = !isEmpty &&
        !isSolvedHighlight &&
        decorationParts.gradient != null;
    final borderRadius =
        decorationParts.borderRadius ?? BorderRadius.circular(8);
    final defaultShadow = BoxShadow(
      color: Colors.black12.withValues(alpha: 0.8),
      spreadRadius: 2,
      blurRadius: 8,
      offset: const Offset(2, 2),
    );
    final List<BoxShadow> combinedShadows = [
      if (isSolvedHighlight)
        BoxShadow(
          color: Colors.orangeAccent.withValues(alpha: 0.65),
          blurRadius: 18,
          spreadRadius: 3.5,
        ),
      if (decorationParts.boxShadows.isNotEmpty)
        ...decorationParts.boxShadows
      else
        defaultShadow,
    ];

    final tileSurface = AnimatedContainer(
      key: ValueKey<String>(widget.letter),
      duration: style.transitionDuration,
      curve: style.switchInCurve,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: useGradient
            ? null
            : isEmpty
            ? Colors.transparent
            : isSolvedHighlight
            ? Colors.orangeAccent.withValues(alpha: 0.82)
            : (_scale != 1.0
            ? baseFillColor.withValues(alpha: 0.5)
            : baseFillColor),
        gradient: useGradient ? decorationParts.gradient : null,
        borderRadius: borderRadius,
        border: decorationParts.border,
        boxShadow: combinedShadows,
      ),
      foregroundDecoration: decorationParts.foregroundDecoration,
      alignment: Alignment.center,
      child: isEmpty
          ? const SizedBox.shrink()
          : Text(
        widget.letter,
        style: const TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    final hintOverlay = Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: isHintHighlight
            ? _HintEffectLayer(
          effect: widget.hintEffect,
          borderRadius: borderRadius,
        )
            : const SizedBox.shrink(),
      ),
    );

    final tileSurfaceWithOverlay = Stack(
      fit: StackFit.expand,
      children: [
        tileSurface,
        hintOverlay,
      ],
    );

    final animatedTile = _applyActiveTransition(tileSurfaceWithOverlay);
    final idleAnimatedTile = _wrapWithIdleAnimation(animatedTile);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: widget.disappearing ? 0.0 : _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeInOut,
        child: idleAnimatedTile,
      ),
    );
  }
}

class _HintEffectLayer extends StatelessWidget {
  final String effect;
  final BorderRadius borderRadius;

  const _HintEffectLayer({
    required this.effect,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    switch (effect) {
      case 'spotlight':
        return _SpotlightHintEffect(borderRadius: borderRadius);
      case 'arrow-bounce':
        return _ArrowBounceHintEffect(borderRadius: borderRadius);
      case 'ring':
      default:
        return _RingHintEffect(borderRadius: borderRadius);
    }
  }
}

class _RingHintEffect extends StatelessWidget {
  const _RingHintEffect({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    const ringColor = Color(0xFF64B5F6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1.05),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: ringColor.withOpacity(0.85),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.45),
                  blurRadius: 22,
                  spreadRadius: 1.6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpotlightHintEffect extends StatelessWidget {
  const _SpotlightHintEffect({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final intensity = 0.2 + (0.55 * value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.55 + value * 0.3,
              colors: [
                Colors.transparent,
                Color(0xFFFFF59D).withOpacity(intensity),
                const Color(0x99FFB74D),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _ArrowBounceHintEffect extends StatelessWidget {
  const _ArrowBounceHintEffect({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -18, end: 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(value, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xAAFF7043),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FF7043),
                            blurRadius: 16,
                            spreadRadius: 1.2,
                          ),
                        ],
                      ),
                      child: const SizedBox(width: 20, height: 38),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(value + 14, 0),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}