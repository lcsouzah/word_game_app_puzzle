import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

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

    final borders = <String>[
      'assets/borders/border_red.png',
      'assets/borders/border_green.png',
      'assets/borders/border_blue.png',
    ];

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
            spacing: 8,
            children: [
              for (final color in colors)
                GestureDetector(
                  onTap: () => settings.updateTileColor(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: settings.tileColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Tile Border',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final path in borders)
                GestureDetector(
                  onTap: () => settings.updateBorderAssetPath(path),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: AssetImage(path)),
                      border: Border.all(
                        color: settings.borderAssetPath == path
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => settings.updateBorderAssetPath(''),
            child: const Text('No Border'),
          ),
        ],
      ),
    );
  }
}