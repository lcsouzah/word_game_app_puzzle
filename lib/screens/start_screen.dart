//Y:\word_game_app_puzzle\lib\screens\start_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import'../utils/category_unlock_manager.dart';

import '../models/alphabet_game.dart';
import '../utils/word_category.dart';
import '../screens/safe_area.dart';

enum DifficultyLevel { easy, moderate, hard }

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



  Future<bool> _showRewardedAd() async {
    final Completer<bool> completer = Completer();

    RewardedAd.load(
      adUnitId: dotenv.env['REWARDED_AD_UNIT_ID']!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad){
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },

            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
              },
          );


          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              if (!completer.isCompleted) completer.complete(true);
              },
            );
          },


          onAdFailedToLoad: (LoadAdError error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

          return completer.future;
  }

  void _promptUnlockCategory(String categoryName) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("🔒 Category Locked"),
          content: const Text("Watch a short ad to unlock this category forever?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                bool rewarded = await _showRewardedAd(); // Step 4

                if (!context.mounted) return;

                if (rewarded) {
                  await CategoryUnlockManager.unlockCategory(categoryName);
                  if (!context.mounted) return;
                  setState(() {
                    _selectedCategoryName = categoryName;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 Category unlocked!')),
                  );

                } else {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Ad not completed. Category still locked.'),
                    ),
                  );
                }
              },
              child: const Text('Watch Ad'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoringOption(ScoringOption option) {
    return Row(
      children: [
        Radio<ScoringOption>(
          value: option,
        ),
        Text(option.name),
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
                  value: _selectedCategoryName,
                  hint: const SizedBox.shrink(),
                  iconSize: 30,
                  isExpanded: true,

                dropdownColor: Colors.transparent.withValues(alpha: 0.8),
                underline: const SizedBox(),
                iconEnabledColor: Colors.cyanAccent,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(
                  color: Colors.cyanAccent, fontSize: 30,
                    fontWeight: FontWeight.bold,  ),

                  onChanged: (String? newValue) async {
                    if (newValue == null) return;

                    if (await CategoryUnlockManager.isCategoryUnlocked(newValue)) {
                      setState(() {
                        _selectedCategoryName = newValue;
                      });
                    } else {
                      final unlocked = await _promptUnlockCategory(newValue);
                      if (unlocked) {
                        setState(() {
                          _selectedCategoryName = newValue;
                        });
                      }
                    }
                  },


                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: FutureBuilder<bool>(
                      future: CategoryUnlockManager.isCategoryUnlocked(category.name),
                      builder: (context, snapshot) {
                        final isUnlocked = snapshot.data ?? false;
                        return Row(
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isUnlocked ? Colors.cyanAccent : Colors.redAccent,
                              ),
                            ),
                            if (!isUnlocked) const Icon(Icons.lock, size:16, color: Colors.redAccent),
                          ],
                        );
                      },
                    ),
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
                  label: Text(level.name),
                  selected: _selectedDifficulty == level,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() {
                        _selectedDifficulty = level;
                      });
                    }
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
            child: RadioGroup<ScoringOption>(
              value: _scoringOption,
              onChanged: _handleRadioValueChanged,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ScoringOption.values.map(_buildScoringOption).toList(),
              ),
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
                splashColor: Colors.orangeAccent.withValues(alpha: 0.5),
                highlightColor: Colors.orangeAccent.withValues(alpha: 0.2),
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
                splashColor: Colors.purpleAccent.withValues(alpha: 0.5),
                highlightColor: Colors.purpleAccent.withValues(alpha: 0.2),

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

                  if(!context.mounted) return;
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
