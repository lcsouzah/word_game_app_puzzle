import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/word_slide/models/tile_border_style.dart';
import 'package:word_game_app/word_slide/screens/store_screen.dart';

/// Screen allowing the player to customise tile colour and border image.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    final colors = <Color>[
      Colors.blueGrey,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    final styles = TileBorderStyles.freeStyles.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tile Colour',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: styles.map((style) {
              final styleDecoration = style.buildDecoration(
                tileColor: settings.tileColor,
                highlighted: false,
              );
              final isSelected = settings.borderStyle.id == style.id;
              return GestureDetector(
                onTap: () {
                  settings.updateBorderStyle(style);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius:
                        styleDecoration.borderRadius ??
                            BorderRadius.circular(8),
                        border: Border.all(
                          color:
                          isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _TilePreview(
                        style: style,
                        tileColor: settings.tileColor,
                        decorationOverride: styleDecoration,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      style.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              settings.updateBorderStyle(TileBorderStyles.defaultStyle);
            },
            child: const Text('Classic Outline'),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Border Store'),
              subtitle: const Text('Browse and unlock new border styles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreScreenProvider(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TilePreview extends StatelessWidget {
  final TileBorderStyle style;
  final Color tileColor;
  final TileBorderDecoration? decorationOverride;

  const _TilePreview({
    required this.style,
    required this.tileColor,
    this.decorationOverride,
  });

  @override
  Widget build(BuildContext context) {
    final styleDecoration = decorationOverride ?? style.buildDecoration(
      tileColor: tileColor,
      highlighted: false,
    );
    final boxDecoration = BoxDecoration(
      color: styleDecoration.gradient == null
          ? styleDecoration.fillColor ?? tileColor
          : null,
      gradient: styleDecoration.gradient,
      borderRadius:
      styleDecoration.borderRadius ?? BorderRadius.circular(8),
      border: styleDecoration.border,
      boxShadow: styleDecoration.boxShadows,
    );

    return Container(
      width: 60,
      height: 60,
      decoration: boxDecoration,
      foregroundDecoration: styleDecoration.foregroundDecoration,
      alignment: Alignment.center,
      child: const Text(
        'A',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}