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
  static const int _gridSize = 8;

  static const List<String> _baseDictionary = [
    'CAT',
    'DOG',
    'BIRD',
    'FISH',
    'HORSE',
  ];

  int _maxWordLengthFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.moderate:
        return 4;
      case DifficultyLevel.hard:
        return 5;
    }
  }

  List<String> _dictionaryFor(DifficultyLevel level) {
    final maxLen = _maxWordLengthFor(level);
    return _baseDictionary.where((w) => w.length <= maxLen).toList();
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
          gridSize: _gridSize,
          dictionary: _dictionaryFor(_difficulty),
          maxWordLength: _maxWordLengthFor(_difficulty),
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