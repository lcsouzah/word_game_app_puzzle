//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';

class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted; // 🔴 highlighted on hint logic
  final bool disappearing; // 🔴 disappearing correct word animation
  final Color tileColor;
  final Color borderAssetPatch;
  final Color tileColor;

  const TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    required this.tileColor,
    required this.borderAssetPatch,
    this.highlighted = false,
    this.disappearing = false,
    this.tileColor = Colors.blueGrey,
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
    final _ = widget.letter.trim().isEmpty;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: widget.disappearing ? 0.0 : _scale, //shrink when disappearing
        duration: const Duration(milliseconds: 50),
        child: Container(
          margin: const EdgeInsets.all(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.letter.trim().isEmpty
                      ? Colors.transparent
                      : widget.tileColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (widget.highlighted)
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.7),
                        blurRadius: 15,
                        spreadRadius: 3,
                      )
                    else
                      BoxShadow(
                        color: Colors.black12.withValues(alpha: 0.8),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: widget.letter.trim().isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                  widget.letter,
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.borderAssetPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.borderAssetPath!,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}