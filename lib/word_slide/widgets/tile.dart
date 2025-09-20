//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';


class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted; // 🔴 highlighted on hint logic
  final bool disappearing; // 🔴 disappearing correct word animation
  final Color tileColor;
  final String? borderAssetPath;
  final TileBorderStyle? borderStyle;

  const TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
    this.disappearing = false,
    this.tileColor = Colors.blueGrey,
    this.borderStyle = TileBorderStyles.defaultStyle,
  });

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
    final visuals = widget.borderStyle.visuals(widget.tileColor);
    final baseFillColor = visuals.fillColor ?? widget.tileColor;
    final bool useGradient =
        !isEmpty && !widget.highlighted && visuals.gradient != null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: widget.disappearing ? 0.0 : _scale, //shrink when disappearing
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
            gradient: useGradient ? visuals.gradient : null,
            borderRadius:
            visuals.borderRadius ?? BorderRadius.circular(8),
            border: visuals.border,
            boxShadow: [
              if (widget.highlighted)
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.7),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ...(
              visuals.boxShadows.isNotEmpty
                  ? visuals.boxShadows
                  : [
                BoxShadow(
                  color: Colors.black12.withValues(alpha: 0.8),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                )
              ],
              ),
            ],
          ),
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