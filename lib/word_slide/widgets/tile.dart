//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/tile_animation_style.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/models/tile_highlight_kind.dart';

class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted;
  final bool disappearing;
  final Color tileColor;
  final Color borderColor;
  final TileBorderStyle borderStyle;
  final TileAnimationStyle animationStyle;
  final TileHighlightKind? highlightKind;
  final String hintEffect;
  final bool idleShimmerEnabled;
  final Color letterColor;
  final double borderWidth;

  TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
    this.disappearing = false,
    this.highlightKind = TileHighlightKind.none,
    this.hintEffect = 'hint.inner_pulse',
    this.idleShimmerEnabled = true,
    Color? letterColor,
    double borderWidth = 2.0,
    Color tileColor = Colors.blueGrey,
    Color? borderColor,
    TileBorderStyle? borderStyle,
    TileAnimationStyle? animationStyle,
  })  : tileColor = tileColor,
        borderColor = borderColor ?? tileColor,
        borderStyle = borderStyle ?? TileBorderStyles.none,
        animationStyle = animationStyle ?? TileAnimationStyles.defaultStyle,
        letterColor = letterColor ?? Colors.white,
        borderWidth = borderWidth;

  @override
  TileWidgetState createState() => TileWidgetState();
}

class TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _idleController;
  Animation<double>? _idleOpacity;
  late final AnimationController _hintPulseController;
  late final Animation<double> _hintPulse;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: _resolveIdleDuration(widget.animationStyle),
    );
    _refreshIdleAnimation(restart: true);
    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hintPulse = CurvedAnimation(
      parent: _hintPulseController,
      curve: Curves.easeInOut,
    );
    _updateHintAnimation(_shouldAnimateHint(widget));
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool styleChanged =
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

    _updateHintAnimation(_shouldAnimateHint(widget));
  }

  @override
  void dispose() {
    _idleController.dispose();
    _hintPulseController.dispose();
    super.dispose();
  }

  Duration _resolveIdleDuration(TileAnimationStyle style) {
    return style.idleLoopPeriod ?? const Duration(milliseconds: 1500);
  }

  double _resolveIdleLowerBound(TileAnimationStyle style) {
    final double lower = style.idleOpacityLowerBound ?? 0.5;
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
    final bool shouldAnimateBlink =
        widget.animationStyle.behavior == TileAnimationBehavior.blink &&
            widget.letter.trim().isNotEmpty;

    if (shouldAnimateBlink) {
      final double lowerBound =
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

  bool _shouldAnimateHint(TileWidget target) {
    return target.highlighted &&
        target.highlightKind == TileHighlightKind.hint &&
        target.letter.trim().isNotEmpty;
  }

  void _updateHintAnimation(bool shouldAnimate) {
    if (shouldAnimate) {
      if (!_hintPulseController.isAnimating) {
        _hintPulseController.repeat(reverse: true);
      }
    } else if (_hintPulseController.isAnimating) {
      _hintPulseController.stop();
      _hintPulseController.value = 0.0;
    }
  }

  void _onTapDown(_) {
    setState(() {
      _scale = 0.8;
    });
  }

  void _onTapUp(_) {
    setState(() {
      _scale = 1.1;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  Widget _wrapWithIdleAnimation(Widget child) {
    final Animation<double>? idleOpacity = _idleOpacity;
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
    final TileAnimationStyle style = widget.animationStyle;
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
            final Animation<Offset> position = animation.drive(
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
            final FadeTransition fade = FadeTransition(
              opacity: animation,
              child: animatedChild,
            );
            final Animation<double> scaleAnimation = animation.drive(
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
            final double overshoot = style.puffScaleFactor ?? 1.1;
            final TweenSequence<double> sequence = TweenSequence<double>([
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
            final Animation<double> scale = animation.drive(sequence);
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
    final TileAnimationStyle style = widget.animationStyle;
    final bool isEmpty = widget.letter.trim().isEmpty;
    final TileBorderDecoration decorationParts =
    widget.borderStyle.buildDecoration(
      tileColor: widget.tileColor,
      borderColor: widget.borderColor,
      highlighted: widget.highlighted,
    );
    final bool isHintHighlight = _shouldAnimateHint(widget);
    final bool isSolvedHighlight =
        widget.highlighted && widget.highlightKind == TileHighlightKind.solved;
    final BorderRadius borderRadius =
        decorationParts.borderRadius ?? BorderRadius.circular(8);
    final Color baseFillColor = decorationParts.fillColor ?? widget.tileColor;
    final Color resolvedFillColor = isEmpty
        ? Colors.transparent
        : isSolvedHighlight
        ? Colors.orangeAccent.withOpacity(0.82)
        : isHintHighlight
        ? baseFillColor.withOpacity(0.92)
        : (_scale != 1.0
        ? baseFillColor.withOpacity(0.58)
        : baseFillColor);

    final BoxShadow defaultShadow = BoxShadow(
      color: Colors.black12.withOpacity(0.8),
      spreadRadius: 2,
      blurRadius: 8,
      offset: const Offset(2, 2),
    );
    final List<BoxShadow> combinedShadows;
    if (isSolvedHighlight) {
      combinedShadows = const <BoxShadow>[
        BoxShadow(
          color: Color(0xFFFFC766),
          blurRadius: 22,
          spreadRadius: 3.0,
        ),
      ];
    } else if (isHintHighlight) {
      combinedShadows = <BoxShadow>[
        BoxShadow(
          color: Colors.white.withOpacity(0.28),
          blurRadius: 20,
          spreadRadius: 2.4,
        ),
        defaultShadow,
      ];
    } else if (decorationParts.boxShadows.isNotEmpty) {
      combinedShadows = decorationParts.boxShadows;
    } else {
      combinedShadows = <BoxShadow>[defaultShadow];
    }

    final BoxDecoration boxDecoration = BoxDecoration(
      color: decorationParts.gradient == null ? resolvedFillColor : null,
      gradient: decorationParts.gradient,
      borderRadius: borderRadius,
      border: Border.all(
        color: widget.borderColor.withOpacity(isHintHighlight ? 0.9 : 1.0),
        width: widget.borderWidth,
      ),
      boxShadow: combinedShadows,
    );

    final AnimatedContainer background = AnimatedContainer(
      key: ValueKey<String>(widget.letter),
      duration: style.transitionDuration,
      curve: style.switchInCurve,
      margin: const EdgeInsets.all(4),
      decoration: boxDecoration,
      foregroundDecoration:
      isHintHighlight ? null : decorationParts.foregroundDecoration,
      child: const SizedBox.expand(),
    );

    final Widget letterWidget = isEmpty
        ? const SizedBox.shrink()
        : _buildLetterWidget(isHintHighlight, isSolvedHighlight);
    final Widget? hintOverlay =
    _buildHintOverlay(borderRadius, isHintHighlight);

    final Stack tileSurfaceWithOverlay = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        background,
        if (hintOverlay != null) Positioned.fill(child: hintOverlay),
        if (!isEmpty) Center(child: letterWidget),
      ],
    );

    final Widget animatedTile = _applyActiveTransition(tileSurfaceWithOverlay);
    final Widget idleAnimatedTile = _wrapWithIdleAnimation(animatedTile);

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

  Widget _buildLetterWidget(bool isHintHighlight, bool isSolvedHighlight) {
    final TextStyle baseStyle = TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: widget.letterColor,
    );

    if (isHintHighlight) {
      final TextStyle strokeStyle = TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.black.withOpacity(0.55),
      );
      final TextStyle fillStyle = baseStyle.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(widget.letter, style: strokeStyle),
          Text(widget.letter, style: fillStyle),
        ],
      );
    }

    return Text(
      widget.letter,
      style: baseStyle.copyWith(
        shadows: isSolvedHighlight
            ? const [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ]
            : null,
      ),
    );
  }

  Widget? _buildHintOverlay(BorderRadius borderRadius, bool isHintHighlight) {
    if (!isHintHighlight) {
      return null;
    }
    return AnimatedBuilder(
      animation: _hintPulseController,
      builder: (context, _) {
        final double t =
        _hintPulseController.isAnimating ? _hintPulse.value : 0.0;
        final double innerFactor = 0.76 + (0.18 * t);
        final double haloOpacity = 0.28 + (0.24 * t);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.32 + 0.20 * t),
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: innerFactor,
                heightFactor: innerFactor,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: Colors.white.withOpacity(0.2 + 0.1 * (1 - t)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(haloOpacity),
                        blurRadius: 18 + 10 * t,
                        spreadRadius: 1.2 + t,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}