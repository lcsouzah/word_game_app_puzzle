//Y:\word_game_app_puzzle\lib\screens\start_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';


import'../utils/category_unlock_manager.dart';

import '../models/alphabet_game.dart';
import '../models/difficulty_level.dart';
import '../utils/word_category.dart';
import '../screens/safe_area.dart';
import '../widgets/start/category_selector.dart';
import '../widgets/start/difficulty_selector.dart';
import '../widgets/start/leaderboard_button.dart';
import '../widgets/start/scoring_options.dart';
import '../widgets/start/start_button.dart';
import '../widgets/start/time_selector.dart';
import '../services/ad_service.dart';

class StartScreen extends StatefulWidget {
  final List<WordCategory> categories;
  final VoidCallback toggleTheme;

  const StartScreen({
    super.key,
    required this.categories,
    required this.toggleTheme,
  });

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  String? _selectedCategoryName;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.easy;
  ScoringOption _scoringOption = ScoringOption.horizontal;
  late int _selectedTime = 180;

  @override
  void initState() {
    super.initState();
    _safeSignIn();

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
        case DifficultyLevel.easy:
          return length < 5;
        case DifficultyLevel.moderate:
          return length >= 5 && length <= 6;
        case DifficultyLevel.hard:
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
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

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



  Future<bool> _promptUnlockCategory(String categoryName) async {
    final rewarded = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("🔒 Category Locked"),
          content: const Text("Watch a short ad to unlock this category forever?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final rewarded = await context.read<AdService>().showRewardedAd();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, rewarded);
              },
              child: const Text('Watch Ad'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!mounted) return false;

    if (rewarded) {
      await CategoryUnlockManager.unlockCategory(categoryName);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Category unlocked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ad not completed. Category still locked.'),
        ),
      );
    }
    return rewarded;
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
            child: CategorySelector(
              categories: widget.categories,
              selectedCategory: _selectedCategoryName,
              isCategoryUnlocked: CategoryUnlockManager.isCategoryUnlocked,
              promptUnlock: _promptUnlockCategory,
              onCategoryChanged: (value) {
                setState(() {
                  _selectedCategoryName = value;
                });
              },
            ),
          ),

          // Difficulty Selector
          Positioned(
            top: MediaQuery.of(context).size.height * 0.505,
            left: MediaQuery.of(context).size.width * 0.03,
            width: MediaQuery.of(context).size.width * 0.95,
            child: DifficultySelector(
              selectedDifficulty: _selectedDifficulty,
              onSelected: (level) {
                setState(() {
                  _selectedDifficulty = level;
                });
              },
            ),
          ),

          // Scoring Options Row
          Positioned(
            top: MediaQuery.of(context).size.height * 0.58,
            left: MediaQuery.of(context).size.width * 0.001,
            width: MediaQuery.of(context).size.width * 0.9,
            child: ScoringOptions(
              groupValue: _scoringOption,
              onChanged: _handleRadioValueChanged,
            ),
          ),

          // Time Selector
          Positioned(
            top: MediaQuery.of(context).size.height * 0.65,
            left: MediaQuery.of(context).size.width * 0.30,
            width: MediaQuery.of(context).size.width * 0.35,
            child: TimeSelector(
              selectedTime: _selectedTime,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTime = value;
                  });
                }
              },
            ),
          ),

          // Start Game Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.748,
            left: MediaQuery.of(context).size.width * 0.14,
            width: MediaQuery.of(context).size.width * 0.72,
            height: 63.5,
            child: StartButton(onTap: _startGame),
          ),

          // Leaderboard Button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.868,
            left: MediaQuery.of(context).size.width * 0.135,
            width: MediaQuery.of(context).size.width * 0.73,
            height: 40,
            child: LeaderboardButton(
              onTap: () async {
                String leaderboardId = switch (_selectedDifficulty) {
                  DifficultyLevel.easy => dotenv.env['EASY_LEADERBOARD_ID']!,
                  DifficultyLevel.moderate => dotenv.env['MODERATE_LEADERBOARD_ID']!,
                  DifficultyLevel.hard => dotenv.env['HARD_LEADERBOARD_ID']!,
                };
                try {
                  await GamesServices.showLeaderboards(
                    androidLeaderboardID: leaderboardId,
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Showing leaderboard.")),
                  );
                } catch (e) {
                  if (kDebugMode) print('Failed to open leaderboard: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Leaderboard not available.")),
                  );
                }
              },
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
