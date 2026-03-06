//Y:\word_game_app_puzzle\lib\screens\start_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/utils/category_unlock_manager.dart';
import 'package:word_game_app/utils/text_format.dart';
import 'package:word_game_app/utils/word_category.dart';
import 'package:word_game_app/word_slide/core/alphabet_game.dart';
import 'package:word_game_app/word_slide/core/game_config.dart';
import 'package:word_game_app/word_slide/ui/screens/safe_area.dart';
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

const List<int> _timerOptions = [60, 120, 180];

class StartScreenState extends State<StartScreen> {
  static const _difficultyKey = 'word_slide_difficulty';
  static const _scoringKey = 'word_slide_scoring';
  static const _timerKey = 'word_slide_timer';

  String? _selectedCategoryName;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.easy;
  ScoringOption _scoringOption = ScoringOption.horizontal;
  late int _selectedTime = 180;
  bool _isStartGlowing = false;
  Timer? _glowTimer;

  @override
  void initState() {
    super.initState();
    _safeSignIn();
    _loadPreferences();
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
      _persistSelection(_scoringKey, value.name);
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDifficulty = prefs.getString(_difficultyKey);
    final storedScoring = prefs.getString(_scoringKey);
    final storedTimer = prefs.getInt(_timerKey);

    setState(() {
      if (storedDifficulty != null) {
        _selectedDifficulty = DifficultyLevel.values.firstWhere(
              (level) => level.name == storedDifficulty,
          orElse: () => _selectedDifficulty,
        );
      }
      if (storedScoring != null) {
        _scoringOption = ScoringOption.values.firstWhere(
              (option) => option.name == storedScoring,
          orElse: () => _scoringOption,
        );
      }
      if (storedTimer != null && _timerOptions.contains(storedTimer)) {
        _selectedTime = storedTimer;
      }
    });
  }

  Future<void> _persistSelection(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value) {
      case int seconds:
        await prefs.setInt(key, seconds);
      case String text:
        await prefs.setString(key, text);
      default:
        await prefs.setString(key, value.toString());
    }
  }

  void _onDifficultySelected(DifficultyLevel level) {
    setState(() => _selectedDifficulty = level);
    _persistSelection(_difficultyKey, level.name);
  }

  void _onTimerChanged(int? value) {
    if (value == null) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedTime = value);
    _persistSelection(_timerKey, value);
  }

  Future<void> _startGame() async {
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isStartGlowing = true);
    _glowTimer?.cancel();
    _glowTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isStartGlowing = false);
      }
    });

    final selectedCategory = widget.categories.firstWhere(
          (cat) => cat.name == _selectedCategoryName,
    );

    final filteredWords = _filterWordsByDifficulty(
      selectedCategory.allWords,
      _selectedDifficulty,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) => SafeAreaScreen(
          scoringOption: _scoringOption,
          gameDuration: _selectedTime,
          wordList: filteredWords,
          difficulty: _selectedDifficulty.name.toLowerCase(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GalaxyBackground(animate: settings.animatedBackgroundEnabled),
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
                        const _NeonTitle(),
                        const SizedBox(height: 8),
                        const Text(
                          'Tune your challenge',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 16),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(text: 'Select Category'),
                              const SizedBox(height: 12),
                              _CategoryDropdown(
                                categories: widget.categories,
                                selectedCategory: _selectedCategoryName,
                                onCategorySelected: (value) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedCategoryName = value);
                                },
                                isCategoryUnlocked:
                                CategoryUnlockManager.isCategoryUnlocked,
                                promptUnlock: _promptUnlockCategory,
                              ),
                              const SizedBox(height: 28),
                              _SectionLabel(text: 'Select Difficulty'),
                              const SizedBox(height: 12),
                              _DifficultyPills(
                                selectedDifficulty: _selectedDifficulty,
                                onSelected: _onDifficultySelected,
                              ),
                              const SizedBox(height: 28),
                              _SectionLabel(text: 'Scoring Type'),
                              const SizedBox(height: 12),
                              _ScoringSelector(
                                selected: _scoringOption,
                                onChanged: _handleRadioValueChanged,
                              ),
                              const SizedBox(height: 28),
                              _SectionLabel(text: 'Timer'),
                              const SizedBox(height: 12),
                              _TimerDropdown(
                                selectedTime: _selectedTime,
                                onChanged: _onTimerChanged,
                              ),
                              const SizedBox(height: 32),
                              NeonButton(
                                text: 'Start Game',
                                glow: _isStartGlowing,
                                onPressed: _startGame,
                              ),
                              NeonButton(
                                text: 'View Leaderboard',
                                color: const Color(0xFF2E1A6F),
                                foregroundColor: const Color(0xFF5CDEFF),
                                isOutlined: true,
                                glow: true,
                                onPressed: () async {
                                  if (!mounted) return;
                                  final leaderboardId = switch (
                                  _selectedDifficulty) {
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
                                      debugPrint(
                                          'Failed to open leaderboard: $e');
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed: widget.toggleTheme,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                  ),
                                  icon: const Icon(Icons.brightness_6_outlined),
                                  label: const Text('Toggle theme'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
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

  @override
  void dispose() {
    _glowTimer?.cancel();
    super.dispose();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF80FFE7),
        fontSize: 14,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NeonTitle extends StatelessWidget {
  const _NeonTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [Color(0xFFFF7B00), Color(0xFFFF4500)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect),
      child: const Text(
        'WORD SLIDE',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 6,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DifficultyPills extends StatelessWidget {
  const _DifficultyPills({
    required this.selectedDifficulty,
    required this.onSelected,
  });

  final DifficultyLevel selectedDifficulty;
  final ValueChanged<DifficultyLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: DifficultyLevel.values.map((level) {
        final isSelected = level == selectedDifficulty;
        final label = titleCaseFirstOnly(level.name);
        return _SelectablePill(
          label: label,
          isSelected: isSelected,
          onTap: () => onSelected(level),
        );
      }).toList(),
    );
  }
}

class _SelectablePill extends StatefulWidget {
  const _SelectablePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SelectablePill> createState() => _SelectablePillState();
}

class _SelectablePillState extends State<_SelectablePill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.isSelected
        ? const Color(0xFF00FFE1)
        : const Color(0xAA4A2A80);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _pressed ? 1.06 : 1.0,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF00FFE1)
                  : const Color(0x664A2A80),
              width: 2,
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: glowColor.withOpacity(0.7),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
            gradient: LinearGradient(
              colors: widget.isSelected
                  ? const [Color(0xFF1D0C3A), Color(0xFF0A1B3C)]
                  : const [Color(0x66180B3A), Color(0x330A1B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? const Color(0xFF00FFE1)
                  : Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoringSelector extends StatelessWidget {
  const _ScoringSelector({
    required this.selected,
    required this.onChanged,
  });

  final ScoringOption selected;
  final ValueChanged<ScoringOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 12,
      spacing: 16,
      children: ScoringOption.values.map((option) {
        final isSelected = option == selected;
        final label = titleCaseFirstOnly(option.name);
        return _NeonRadioChip(
          label: label,
          isSelected: isSelected,
          onTap: () => onChanged(option),
        );
      }).toList(),
    );
  }
}

class _NeonRadioChip extends StatefulWidget {
  const _NeonRadioChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NeonRadioChip> createState() => _NeonRadioChipState();
}

class _NeonRadioChipState extends State<_NeonRadioChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _pressed ? 1.06 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF00FFE1)
                  : const Color(0x553F2B70),
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: const Color(0xFF00FFE1).withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
            color: widget.isSelected
                ? const Color(0x3300FFE1)
                : const Color(0x220D0630),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFF00FFE1)
                        : Colors.white30,
                    width: 2,
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2.8),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? const Color(0xFF00FFE1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerDropdown extends StatelessWidget {
  const _TimerDropdown({
    required this.selectedTime,
    required this.onChanged,
  });

  final int selectedTime;
  final ValueChanged<int?> onChanged;

  String _labelFor(int value) {
    final minutes = value ~/ 60;
    return minutes == 1 ? '1 Minute' : '$minutes Minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00FFE1), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5500FFE1),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0x3318003A), Color(0x330A1B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedTime,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00FFE1)),
          dropdownColor: const Color(0xFF100429),
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          onChanged: onChanged,
          items: _timerOptions
              .map(
                (value) => DropdownMenuItem<int>(
              value: value,
              child: Text(_labelFor(value)),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isCategoryUnlocked,
    required this.promptUnlock,
  });

  final List<WordCategory> categories;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Future<bool> Function(String category) isCategoryUnlocked;
  final Future<bool> Function(String category) promptUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5CDEFF), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x445CDEFF),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0x3318003A), Color(0x330A1B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5CDEFF)),
          dropdownColor: const Color(0xFF0B0124),
          borderRadius: BorderRadius.circular(18),
          hint: const Text(
            'Choose a category',
            style: TextStyle(color: Colors.white60),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (value) async {
            if (value == null) return;
            if (await isCategoryUnlocked(value)) {
              onCategorySelected(value);
            } else {
              final unlocked = await promptUnlock(value);
              if (unlocked) {
                onCategorySelected(value);
              }
            }
          },
          items: categories
              .map(
                (category) => DropdownMenuItem<String>(
              value: category.name,
              child: FutureBuilder<bool>(
                future: isCategoryUnlocked(category.name),
                builder: (context, snapshot) {
                  final unlocked = snapshot.data ?? false;
                  return Row(
                    children: [
                      Text(
                        titleCaseFirstOnly(category.name),
                        style: TextStyle(
                          color: unlocked
                              ? const Color(0xFF5CDEFF)
                              : const Color(0xFFFF5F84),
                        ),
                      ),
                      if (!unlocked) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock,
                            size: 16, color: Color(0xFFFF5F84)),
                      ],
                    ],
                  );
                },
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFFF7B00),
    this.foregroundColor = Colors.white,
    this.isOutlined = false,
    this.glow = false,
  });

  final String text;
  final FutureOr<void> Function() onPressed;
  final Color color;
  final Color foregroundColor;
  final bool isOutlined;
  final bool glow;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  void _handleTap() {
    final result = widget.onPressed();
    if (result is Future) {
      unawaited(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = widget.isOutlined
        ? widget.foregroundColor.withOpacity(widget.glow ? 0.7 : 0.35)
        : widget.color.withOpacity(widget.glow ? 0.8 : 0.6);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            color: widget.isOutlined ? Colors.transparent : widget.color,
            borderRadius: BorderRadius.circular(24),
            border: widget.isOutlined
                ? Border.all(color: widget.foregroundColor, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: widget.glow ? 28 : 18,
                spreadRadius: widget.glow ? 4 : 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text.toUpperCase(),
              style: TextStyle(
                color: widget.foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalaxyBackground extends StatefulWidget {
  const _GalaxyBackground({required this.animate});

  final bool animate;

  @override
  State<_GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<_GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _stars = List<_Star>.generate(60, (index) {
      final random = Random(index * 17);
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        size: random.nextDouble() * 2.5 + 0.8,
        velocity: Offset(random.nextDouble() * 0.004 - 0.002,
            random.nextDouble() * 0.004 - 0.002),
        twinkleOffset: random.nextDouble() * pi * 2,
      );
    });
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _GalaxyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = widget.animate ? _controller.value : 0.0;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF18002E),
                Color(0xFF3A1172),
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _StarfieldPainter(
              stars: _stars,
              progress: progress,
            ),
          ),
        );
      },
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.size,
    required this.velocity,
    required this.twinkleOffset,
  });

  final double dx;
  final double dy;
  final double size;
  final Offset velocity;
  final double twinkleOffset;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter({
    required this.stars,
    required this.progress,
  });

  final List<_Star> stars;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final dx = (star.dx + star.velocity.dx * progress) % 1;
      final dy = (star.dy + star.velocity.dy * progress) % 1;
      final position = Offset(dx * size.width, dy * size.height);
      final twinkle = 0.5 + 0.5 *
          sin((progress * 2 * pi) + star.twinkleOffset);
      final radius = star.size * twinkle;
      paint
        ..color = const Color(0xFFBBE7FF).withOpacity(0.5 + 0.5 * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.stars != stars;
  }
}