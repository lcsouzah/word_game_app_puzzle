//Y:\word_game_app_puzzle\lib\screens\start_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import '../models/alphabet_game.dart';
import '../utils/word_category.dart';
import '../utils/sound_manager.dart';
import '../screens/safe_area.dart';

enum DifficultyLevel { Easy, Moderate, Hard }

class StartScreen extends StatefulWidget {
  final List<WordCategory> categories;
  final VoidCallback toggleTheme;

  const StartScreen({
    super.key,
    required this.categories,
    required this.toggleTheme,
  });

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _selectedCategoryName;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.Easy;
  ScoringOption _scoringOption = ScoringOption.Horizontal;
  late int _selectedTime = 180;

  @override
  void initState() {
    super.initState();
    _safeSignIn();
    if (widget.categories.isNotEmpty) {
      _selectedCategoryName = widget.categories.first.name;
    }
  }

  void _safeSignIn() async {
    try {
      await GamesServices.signIn();
    } catch (e) {
      if (kDebugMode) print("Sign-in failed: $e");
    }
  }

  List<String> _filterWordsByDifficulty(List<String> allWords, DifficultyLevel difficulty) {
    return allWords.where((word) {
      final length = word.length;
      switch (difficulty) {
        case DifficultyLevel.Easy:
          return length < 5;
        case DifficultyLevel.Moderate:
          return length >= 5 && length <= 6;
        case DifficultyLevel.Hard:
          return length > 6;
      }
    }).toList();
  }

  void _handleRadioValueChanged(ScoringOption? value) {
    if (value != null) {
      setState(() {
        _scoringOption = value;
      });
    }
  }

  void _startGame() {
    final selectedCategory = widget.categories.firstWhere(
          (cat) => cat.name == _selectedCategoryName,
    );

    final filteredWords = _filterWordsByDifficulty(
      selectedCategory.allWords,
      _selectedDifficulty,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SafeAreaScreen(
          scoringOption: _scoringOption,
          gameDuration: _selectedTime,
          wordList: filteredWords,
          difficulty: _selectedDifficulty.name.toLowerCase(),
        ),
      ),
    );
  }

  Widget _buildScoringOption(ScoringOption option) {
    return Row(
      children: [
        Radio<ScoringOption>(
          value: option,
          groupValue: _scoringOption,
          onChanged: _handleRadioValueChanged,
        ),
        Text(describeEnum(option)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/word_slide_startscreen.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Title
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "START SCREEN",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Category Dropdown
          Positioned(
            top: MediaQuery.of(context).size.height * 0.364,
            left: MediaQuery.of(context).size.width * 0.1285,
            width: MediaQuery.of(context).size.width * 0.78,
            height: 49,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButton<String>(
                value: null ,
                iconSize: 30,
                isExpanded: true,

                dropdownColor: Colors.transparent.withOpacity(0.8),
                underline: const SizedBox(),
                iconEnabledColor: Colors.cyanAccent,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(
                  color: Colors.cyanAccent, fontSize: 30,
                    fontWeight: FontWeight.bold,  ),

                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryName = newValue;
                  });
                },
                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
              ),
            ),
          ),

          // Difficulty Selector
          Positioned(
            top: MediaQuery.of(context).size.height * 0.505,
            left: MediaQuery.of(context).size.width * 0.03,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: DifficultyLevel.values.map((level) {
                String label = level.toString().split('.').last;

                return ChoiceChip(
                  backgroundColor: Colors.deepPurple.shade400,
                  shadowColor: Colors.red,
                  selectedColor: Colors.deepPurple.shade300,
                  selectedShadowColor: Colors.greenAccent,
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 15,
                  labelPadding: const EdgeInsets.all(5),
                  label: Text(describeEnum(level)),
                  selected: _selectedDifficulty == level,
                  onSelected: (_) {
                    setState(() {
                      _selectedDifficulty = level;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Scoring Options Row
          Positioned(
            top: MediaQuery.of(context).size.height * 0.58,
            left: MediaQuery.of(context).size.width * 0.001,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ScoringOption.values.map(_buildScoringOption).toList(),
            ),
          ),

          // Time Selector
          Positioned(
            top: MediaQuery.of(context).size.height * 0.65,
            left: MediaQuery.of(context).size.width * 0.30,
            width: MediaQuery.of(context).size.width * 0.35,
            child: DropdownButton<int>(
              iconSize: 24,
              value: _selectedTime,
              dropdownColor: Colors.black,
              iconEnabledColor: Colors.orange,
              style: const TextStyle(color: Colors.orangeAccent),
              underline: Container(height: 3, width: 3, color: Colors.orange),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedTime = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem<int>(value: 60,  child: Text(
                  "1 Minute",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                ),),
                DropdownMenuItem<int>(value: 120, child: Text(
                    '2 Minutes',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                )),
                DropdownMenuItem<int>(value: 180, child: Text(
                    '3 Minutes',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                )),
              ],
            ),
          ),

          // Start Game Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.748,
            left: MediaQuery.of(context).size.width * 0.14,
            width: MediaQuery.of(context).size.width * 0.72,
            height: 63.5,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.orangeAccent.withOpacity(0.5),
                highlightColor: Colors.orangeAccent.withOpacity(0.2),
                onTap: _startGame,
                child: const Text(""),
            ),
          ),
          ),

          // Leaderboard Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.868,
            left: MediaQuery.of(context).size.width * 0.135,
            width: MediaQuery.of(context).size.width * 0.73,
            height: 40,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.purpleAccent.withOpacity(0.5),
                highlightColor: Colors.purpleAccent.withOpacity(0.2),

                onTap: () async {
                String leaderboardId = switch (_selectedDifficulty) {
                  DifficultyLevel.Easy => 'CgkIr_H04_cJEAIQAg',
                  DifficultyLevel.Moderate => 'CgkIr_H04_cJEAIQAw',
                  DifficultyLevel.Hard => 'CgkIr_H04_cJEAIQBA',
                };
                try {
                  await GamesServices.showLeaderboards(
                    androidLeaderboardID: leaderboardId,
                  );
                } catch (e) {
                  if (kDebugMode) print('Failed to open leaderboard: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Leaderboard not available.")),
                  );
                }
              },
              child: const Text(""),
            ),
          ),
          ),

          // Toggle Theme Button (top-right)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            right: 16,
            child: IconButton(
              onPressed: widget.toggleTheme,
              icon: const Icon(Icons.brightness_6, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
