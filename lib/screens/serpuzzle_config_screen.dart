import 'package:flutter/material.dart';
import '../models/difficulty_level.dart';
import './serpuzzle_game_screen.dart';

class SerpuzzleConfigScreen extends StatefulWidget {
  const SerpuzzleConfigScreen({super.key});

  @override
  State<SerpuzzleConfigScreen> createState() => _SerpuzzleConfigScreenState();
}

class _SerpuzzleConfigScreenState extends State<SerpuzzleConfigScreen> {
  DifficultyLevel _difficulty = DifficultyLevel.easy;
  bool _centerStart = true;

  int _gridSizeFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 4;
      case DifficultyLevel.moderate:
        return 5;
      case DifficultyLevel.hard:
        return 6;
    }
  }


  int _seededWordsFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 1;
      case DifficultyLevel.moderate:
        return 2;
      case DifficultyLevel.hard:
        return 3;
    }
  }

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SerpuzzleGameScreen(
          gridSize: _gridSizeFor(_difficulty),
          dictionary: const ['CAT', 'DOG', 'BIRD', 'FISH'],
          seededWordCount: _seededWordsFor(_difficulty),
          startCentered: _centerStart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serpuzzle Config')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<DifficultyLevel>(
              value: _difficulty,
              onChanged: (val) {
                if (val != null) setState(() => _difficulty = val);
              },
              items: const [
                DropdownMenuItem(
                  value: DifficultyLevel.easy,
                  child: Text('Easy'),
                ),
                DropdownMenuItem(
                  value: DifficultyLevel.moderate,
                  child: Text('Moderate'),
                ),
                DropdownMenuItem(
                  value: DifficultyLevel.hard,
                  child: Text('Hard'),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Start Centered'),
              value: _centerStart,
              onChanged: (val) => setState(() => _centerStart = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}