//Y:\word_game_app_puzzle\lib\screens\start_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/utils/category_unlock_manager.dart';
import 'package:word_game_app/utils/text_format.dart';
import 'package:word_game_app/utils/word_category.dart';
import 'package:word_game_app/word_slide/models/alphabet_game.dart';
import 'package:word_game_app/word_slide/models/difficulty_level.dart';
import 'package:word_game_app/word_slide/screens/safe_area.dart';
import 'package:word_game_app/word_slide/widgets/start/category_selector.dart';
import 'package:word_game_app/word_slide/widgets/start/difficulty_selector.dart';
import 'package:word_game_app/word_slide/widgets/start/leaderboard_button.dart';
import 'package:word_game_app/word_slide/widgets/start/scoring_options.dart';
import 'package:word_game_app/word_slide/widgets/start/time_selector.dart';
import 'package:word_game_app/services/ad_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    required this.categories,
    required this.toggleTheme,
  });

  final List<WordCategory> categories;
  final VoidCallback toggleTheme;

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
      if (kDebugMode) {
        debugPrint('Sign-in failed: $e');
      }
    }
  }

  List<String> _filterWordsByDifficulty(
      List<String> allWords,
      DifficultyLevel difficulty,
      ) {
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
      setState(() => _scoringOption = value);
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
          title: const Text('🔒 Category Locked'),
          content: const Text(
            'Watch a short ad to unlock this category forever?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final rewarded =
                await context.read<AdService>().showRewardedAd();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, rewarded);
              },
              child: const Text('Watch Ad'),
            ),
          ],
        );
      },
    ) ??
        false;

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

  Widget _buildSectionTitle(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        titleCaseFirstOnly(label),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StartScreenBackdrop(),
          if (settings.animatedBackgroundEnabled)
            const _AnimatedTileBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Word Slide',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Slide tiles to uncover hidden words',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle(theme, 'category'),
                        CategorySelector(
                          categories: widget.categories,
                          selectedCategory: _selectedCategoryName,
                          isCategoryUnlocked:
                          CategoryUnlockManager.isCategoryUnlocked,
                          promptUnlock: _promptUnlockCategory,
                          onCategoryChanged: (value) {
                            setState(() => _selectedCategoryName = value);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'difficulty'),
                        DifficultySelector(
                          selectedDifficulty: _selectedDifficulty,
                          onSelected: (level) {
                            setState(() => _selectedDifficulty = level);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'scoring'),
                        ScoringOptions(
                          groupValue: _scoringOption,
                          onChanged: _handleRadioValueChanged,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'time limit'),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TimeSelector(
                            selectedTime: _selectedTime,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedTime = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _startGame,
                            child: const Text('Start game'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LeaderboardButton(
                          onTap: () async {
                            if (!mounted) return;
                            final leaderboardId = switch (_selectedDifficulty) {
                              DifficultyLevel.easy =>
                              dotenv.env['LEADERBOARD_ID_EASY']!,
                              DifficultyLevel.moderate =>
                              dotenv.env['LEADERBOARD_ID_MEDIUM']!,
                              DifficultyLevel.hard =>
                              dotenv.env['LEADERBOARD_ID_HARD']!,
                            };
                            try {
                              await GamesServices.showLeaderboards(
                                iOSLeaderboardID: leaderboardId,
                                androidLeaderboardID: leaderboardId,
                              );
                            } catch (e) {
                              if (kDebugMode) {
                                debugPrint('Failed to open leaderboard: $e');
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.toggleTheme,
                          icon: const Icon(Icons.brightness_6),
                          label: const Text('Toggle theme'),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartScreenBackdrop extends StatelessWidget {
  const _StartScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E2F), Color(0xFF2A2A48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _AnimatedTileBackdrop extends StatefulWidget {
  const _AnimatedTileBackdrop();

  @override
  State<_AnimatedTileBackdrop> createState() => _AnimatedTileBackdropState();
}

class _AnimatedTileBackdropState extends State<_AnimatedTileBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<int> _tiles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _tiles = List<int>.generate(16, (index) => index);
    for (var i = 0; i < 12; i++) {
      _stepBoard(animate: false);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stepBoard();
        _controller.forward(from: 0);
      }
    })
      ..forward();
  }

  void _stepBoard({bool animate = true}) {
    final blankIndex = _tiles.indexOf(15);
    final row = blankIndex ~/ 4;
    final col = blankIndex % 4;
    final candidates = <int>[
      if (row > 0) blankIndex - 4,
      if (row < 3) blankIndex + 4,
      if (col > 0) blankIndex - 1,
      if (col < 3) blankIndex + 1,
    ];
    final swapIndex = candidates[_random.nextInt(candidates.length)];
    void applySwap() {
      final temp = _tiles[swapIndex];
      _tiles[swapIndex] = 15;
      _tiles[blankIndex] = temp;
    }

    if (animate) {
      setState(applySwap);
    } else {
      applySwap();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = min(constraints.maxWidth, constraints.maxHeight);
            final tileSize = size / 4;
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    for (var index = 0; index < _tiles.length; index++)
                      if (_tiles[index] != 15)
                        _DecorativeTile(
                          tileSize: tileSize,
                          gridIndex: index,
                          label: String.fromCharCode(65 + _tiles[index]),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DecorativeTile extends StatelessWidget {
  const _DecorativeTile({
    required this.tileSize,
    required this.gridIndex,
    required this.label,
  });

  final double tileSize;
  final int gridIndex;
  final String label;

  @override
  Widget build(BuildContext context) {
    final row = gridIndex ~/ 4;
    final col = gridIndex % 4;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOut,
      left: col * tileSize,
      top: row * tileSize,
      width: tileSize,
      height: tileSize,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}