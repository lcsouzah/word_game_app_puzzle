//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';


class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted; // 🔴 highlighted on hint logic
  final bool disappearing; // 🔴 disappearing correct word animation
  final Color tileColor;
  final Color borderColor;
  final TileBorderStyle borderStyle;

  TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
    this.disappearing = false,
    Color tileColor = Colors.blueGrey,
    Color? borderColor,
    TileBorderStyle? borderStyle,
  })  : tileColor = tileColor,
        borderColor = borderColor ?? tileColor,
        borderStyle = borderStyle ?? TileBorderStyles.none;


  @override
  TileWidgetState createState() => TileWidgetState();

}

class TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

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

  @override
  Widget build(BuildContext context) {

    final isEmpty = widget.letter.trim().isEmpty;
    final decorationParts = widget.borderStyle.buildDecoration(
      tileColor: widget.tileColor,
      borderColor: widget.borderColor,
      highlighted: widget.highlighted,
    );
    final baseFillColor = decorationParts.fillColor ?? widget.tileColor;
    final bool useGradient = !isEmpty &&
        !widget.highlighted &&
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
      if (widget.highlighted)
        BoxShadow(
          color: Colors.greenAccent.withValues(alpha: 0.7),
          blurRadius: 15,
          spreadRadius: 3,
        ),
      if (decorationParts.boxShadows.isNotEmpty)
        ...decorationParts.boxShadows
      else
        defaultShadow,
    ];

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: widget.disappearing ? 0.0 : _scale, // shrink when disappearing
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: useGradient
                ? null
                : isEmpty
                ? Colors.transparent
                : widget.highlighted
                ? Colors.greenAccent.withValues(alpha: 0.8)
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
          child: isEmpty // 🟢 empty tile black
              ? const SizedBox.shrink() // 🟢 empty tile black
              : Text(
            widget.letter,
            style: const TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

}