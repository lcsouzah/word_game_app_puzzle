//Y:\word_game_app_puzzle\lib\widget\tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

class TileWidget extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final bool highlighted; // 🔴 highlighted on hint logic
  final bool disappearing; // 🔴 disappearing correct word animation
  final Color tileColor;
  final String? borderAssetPath;

  const TileWidget({
    super.key,
    required this.letter,
    required this.onTap,
    this.highlighted = false,
    this.disappearing = false,
    this.tileColor = Colors.blueGrey,
    this.borderAssetPath,
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
    final settings = Provider.of<SettingsService>(context);
    final isEmpty = widget.letter.trim().isEmpty;

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
            color: isEmpty
                ? Colors.transparent
                : widget.highlighted
                ? Colors.greenAccent.withValues(alpha: 0.8)
                : (_scale != 1.0
                ? settings.tileColor.withValues(alpha: 0.5)
                : settings.tileColor),
            borderRadius: BorderRadius.circular(8),
            image: settings.borderAssetPath.isEmpty
                ? null
                : DecorationImage(
              image: AssetImage(settings.borderAssetPath),
              fit: BoxFit.fill,
            ),
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
        ),
      ),
    );
  }

}