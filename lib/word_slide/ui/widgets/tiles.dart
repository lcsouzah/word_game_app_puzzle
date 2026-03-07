//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:word_game_app/services/cosmetic_manager.dart';
import 'package:word_game_app/word_slide/ui/theme/board_theme.dart';

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
  final HintEffectConfig hintEffectConfig;
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
    HintEffectConfig? hintEffectConfig,
  })  : tileColor = tileColor,
        borderColor = borderColor ?? tileColor,
        borderStyle = borderStyle ?? TileBorderStyles.none,
        animationStyle = animationStyle ?? TileAnimationStyles.defaultStyle,
        letterColor = letterColor ?? Colors.white,
        borderWidth = borderWidth,
        hintEffectConfig = hintEffectConfig ?? HintEffectConfig.classic;

  @override
  TileWidgetState createState() => TileWidgetState();
}

class TileWidgetState extends State<TileWidget>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _idleController;
  Animation<double>? _idleOpacity;
  late final AnimationController _hintPulse;
  late final Animation<double> _hintScale;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: _resolveIdleDuration(widget.animationStyle),
    );
    _refreshIdleAnimation(restart: true);
    _initHint();
    _updateHintState(_isHintActive(widget));
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

    _updateHintState(_isHintActive(widget));
  }

  @override
  void dispose() {
    _idleController.dispose();
    _hintPulse.dispose();
    super.dispose();
  }

  void _initHint() {
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintScale = Tween<double>(begin: 0.95, end: 1.02)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_hintPulse);
    _hintPulse.value = 1.0;
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

  bool _isHintActive(TileWidget target) {
    return target.highlighted &&
        target.highlightKind == TileHighlightKind.hint &&
        target.letter.trim().isNotEmpty;
  }

  void _updateHintState(bool shouldAnimate) {
    if (shouldAnimate) {
      if (!_hintPulse.isAnimating) {
        _hintPulse.repeat(reverse: true);
      }
    } else {
      if (_hintPulse.isAnimating) {
        _hintPulse.stop();
      }
      _hintPulse.value = 1.0;
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
    final bool isHintActive = _isHintActive(widget);
    _updateHintState(isHintActive);
    final bool isSolvedHighlight =
        widget.highlighted && widget.highlightKind == TileHighlightKind.solved;
    final BorderRadius borderRadius =
        decorationParts.borderRadius ?? BorderRadius.circular(8);
    final Color baseFillColor = decorationParts.fillColor ?? widget.tileColor;
    final Color resolvedFillColor = isEmpty
        ? Colors.transparent
        : isSolvedHighlight
        ? Colors.orangeAccent.withOpacity(0.82)
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
    } else if (decorationParts.boxShadows.isNotEmpty) {
      combinedShadows = decorationParts.boxShadows;
    } else {
      combinedShadows = <BoxShadow>[defaultShadow];
    }

    final Border? resolvedBorder = decorationParts.border ??
        Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        );

    final BoxDecoration boxDecoration = BoxDecoration(
      color: decorationParts.gradient == null ? resolvedFillColor : null,
      gradient: decorationParts.gradient,
      borderRadius: borderRadius,
      border: resolvedBorder,
      boxShadow: combinedShadows,
    );

    final AnimatedContainer background = AnimatedContainer(
      key: ValueKey<String>(widget.letter),
      duration: style.transitionDuration,
      curve: style.switchInCurve,
      margin: const EdgeInsets.all(4),
      decoration: boxDecoration,
      foregroundDecoration: decorationParts.foregroundDecoration,
      child: const SizedBox.expand(),
    );

    final HintEffectConfig hintConfig = widget.hintEffectConfig;
    final bool showHintLetterHighlight = isHintActive &&
        hintConfig.luminousIds.contains('letterHighlight');

    final Widget letterWidget = isEmpty
        ? const SizedBox.shrink()
        : _buildLetterWidget(
      isSolvedHighlight: isSolvedHighlight,
      showHintLetterHighlight: showHintLetterHighlight,
    );

    final Widget baseTile = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        background,
        if (!isEmpty) Center(child: letterWidget),
      ],
    );

    Widget tileCore = baseTile;
    if (isHintActive) {
      final Widget sizedTile =
      _applyHintSizeEffects(baseTile, hintConfig.sizeIds);
      final List<Widget> luminousLayers = _buildHintLuminousOverlays(
        luminousIds: hintConfig.luminousIds,
        borderRadius: borderRadius,
      );
      if (luminousLayers.isEmpty) {
        tileCore = sizedTile;
      } else {
        tileCore = Stack(
          clipBehavior: Clip.none,
          children: [
            sizedTile,
            ...luminousLayers,
          ],
        );
      }
    }

    final Widget animatedTile = _applyActiveTransition(tileCore);
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

  Widget _buildLetterWidget({
    required bool isSolvedHighlight,
    required bool showHintLetterHighlight,
  }) {
    final TextStyle baseStyle = TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: widget.letterColor,
    );

    if (showHintLetterHighlight) {
      final Color glowColor =
          Color.lerp(widget.letterColor, Colors.white, 0.4) ?? Colors.white;
      final TextStyle strokeStyle = baseStyle.copyWith(
        color: null,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = Colors.white.withOpacity(0.6),
      );
      final TextStyle glowStyle = baseStyle.copyWith(
        color: glowColor,
        shadows: [
          Shadow(
            color: const Color(0xFF93F9FF).withOpacity(0.9),
            blurRadius: 18,
          ),
          Shadow(
            color: Colors.white.withOpacity(0.45),
            blurRadius: 26,
          ),
        ],
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          Text(widget.letter, style: strokeStyle),
          Text(widget.letter, style: glowStyle),
        ],
      );
    }

    final TextStyle resolvedStyle = baseStyle.copyWith(
      shadows: isSolvedHighlight
          ? const [
        Shadow(
          color: Color(0x66000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ]
          : null,
    );

    return Text(
      widget.letter,
      style: resolvedStyle,
    );
  }

  Widget _applyHintSizeEffects(Widget child, List<String> sizeIds) {
    Widget current = child;
    for (final String effectId in sizeIds) {
      switch (effectId) {
        case 'scalePulse':
          current = ScaleTransition(
            scale: _hintScale,
            child: current,
          );
          break;
        case 'microBounce':
          final Widget previous = current;
          current = AnimatedBuilder(
            animation: _hintPulse,
            child: previous,
            builder: (context, child) {
              final double offset = (_hintPulse.value - 0.5) * 0.04;
              return Transform.scale(
                scale: 0.98 + offset,
                child: child,
              );
            },
          );
          break;
        default:
          break;
      }
    }
    return current;
  }

  List<Widget> _buildHintLuminousOverlays({
    required List<String> luminousIds,
    required BorderRadius borderRadius,
  }) {
    final List<Widget> overlays = <Widget>[];
    if (luminousIds.contains('innerPulse')) {
      overlays.add(
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _hintPulse,
              builder: (context, _) {
                final double t = _hintPulse.value;
                final double opacity = 0.2 + (1 - t) * 0.3;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withOpacity(opacity),
                        Colors.white.withOpacity(opacity * 0.25),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    if (luminousIds.contains('haloSoft')) {
      overlays.add(
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _hintPulse,
              builder: (context, _) {
                final double t = _hintPulse.value;
                final double haloOpacity = 0.25 + (1 - t) * 0.35;
                final double blurRadius = 18 + (1 - t) * 12;
                final double spreadRadius = 1.0 + (1 - t) * 2.2;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color:
                        const Color(0xFF8BF0FF).withOpacity(haloOpacity),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return overlays;
  }
}
/// Lightweight preview widget that renders a single tile using the current
/// cosmetic selections. This mirrors the runtime [TileWidget] behaviour to
/// ensure settings previews match gameplay visuals.
class TilePreview extends StatelessWidget {
  const TilePreview({
    super.key,
    required this.letter,
    required this.tileColor,
    required this.borderColor,
    required this.borderStyle,
    required this.animationStyle,
    this.hintEffect = 'ring',
    this.showHintEffect = false,
    this.idleShimmerEnabled = false,
  });

  final String letter;
  final Color tileColor;
  final Color borderColor;
  final TileBorderStyle borderStyle;
  final TileAnimationStyle animationStyle;
  final String hintEffect;
  final bool showHintEffect;
  final bool idleShimmerEnabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 64,
        height: 64,
        child: TileWidget(
          letter: letter,
          onTap: () {},
          tileColor: tileColor,
          borderColor: borderColor,
          borderStyle: borderStyle,
          animationStyle: animationStyle,
          highlightKind:
          showHintEffect ? TileHighlightKind.hint : TileHighlightKind.none,
          idleShimmerEnabled: idleShimmerEnabled,
          hintEffect: hintEffect,
          hintEffectConfig:
          showHintEffect ? HintEffectConfig.classic : HintEffectConfig.none,
        ),
      ),
    );
  }
}

class TouchFeedbackOverlay extends StatefulWidget {
  final Widget child;

  const TouchFeedbackOverlay({super.key, required this.child});

  @override
  State<TouchFeedbackOverlay> createState() => _TouchFeedbackOverlayState();
}

class _TouchFeedbackOverlayState extends State<TouchFeedbackOverlay> {
  final List<Offset> _tapPositions = [];

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPositions.add(details.globalPosition);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _tapPositions.isNotEmpty) {
        setState(() {
          _tapPositions.removeAt(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ripples = _tapPositions
        .map(
          (pos) => Positioned(
        left: pos.dx - 12,
        top: pos.dy - 12,
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 0.5,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    )
        .toList();

    return GestureDetector(
      onTapDown: _handleTapDown,
      child: Stack(
        children: [
          widget.child,
          ...ripples,
        ],
      ),
    );
  }
}