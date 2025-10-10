import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/serpuzzle/models/difficulty_level.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_controller.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_game_screen.dart';
import 'package:word_game_app/utils/pause_manager.dart';


class SerpuzzleSafeScreen extends StatefulWidget {
  const SerpuzzleSafeScreen({
    super.key,
    required this.gridSize,
    required this.dictionary,
    required this.maxWordLength,
    this.startCentered = true,
    this.moveDelay = const Duration(milliseconds: 300),
    this.levelTimeLimit = const Duration(minutes: 1),
    this.wrapAround = false,
    this.difficulty = DifficultyLevel.easy,
  });

  final int gridSize;
  final List<String> dictionary;
  final int maxWordLength;
  final bool startCentered;
  final Duration moveDelay;
  final Duration levelTimeLimit;
  final bool wrapAround;
  final DifficultyLevel difficulty;

  @override
  State<SerpuzzleSafeScreen> createState() => _SerpuzzleSafeScreenState();
}

class _SerpuzzleSafeScreenState extends State<SerpuzzleSafeScreen> {
  late final SerpuzzleGameController _controller;
  final GlobalKey<SerpuzzleGameScreenState> _gameKey = GlobalKey();
  PauseManager? _pauseManager;
  bool _bootstrappedTimer = false;
  bool get _isOverlayBlocking =>
      (_pauseManager?.isPaused ?? false) || _controller.isPaused;


  @override
  void initState() {
    super.initState();
    _controller = SerpuzzleGameController(
      levelTimeLimit: widget.levelTimeLimit,
      initialLives: _initialLivesFor(widget.difficulty),
      gridSize: widget.gridSize,
      dictionary: widget.dictionary,
      maxWordLength: widget.maxWordLength,
      startCentered: widget.startCentered,
      moveDelay: widget.moveDelay,
      wrapAround: widget.wrapAround,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pauseManager = Provider.of<PauseManager>(context);
    if (_pauseManager != pauseManager) {
      _pauseManager?.removeListener(_handlePauseStateChanged);
      _pauseManager = pauseManager;
      _pauseManager!.addListener(_handlePauseStateChanged);
    }
    if (!_bootstrappedTimer) {
      _bootstrappedTimer = true;
      if (_pauseManager?.isPaused ?? false) {
        _controller.pause();
      } else {
        _controller.startLevelTimer(resetElapsed: true);
      }
    }
  }

  @override
  void dispose() {
    _pauseManager?.removeListener(_handlePauseStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handlePauseStateChanged() {
    if (!mounted) return;
    final pauseManager = _pauseManager;
    if (pauseManager == null) return;
    if (pauseManager.isPaused) {
      _controller.pause();
    } else {
      _controller.resume();
    }
    setState(() {});
  }

  void _togglePause() {
    final pauseManager = _pauseManager;
    if (pauseManager == null) return;
    if (pauseManager.isPaused && pauseManager.pauseReason == PauseReason.manual) {
      pauseManager.resume(PauseReason.manual);
    } else {
      pauseManager.pause(PauseReason.manual);
    }
  }

  Widget _buildPauseOverlay() {
    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _isOverlayBlocking ? 1 : 0.95,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: _isOverlayBlocking ? 1 : 0,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_circle_filled, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Paused',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Wrap(
                        spacing: 12,
                        children: [
                          _Badge(icon: Icons.flag, label: 'Level ${_controller.level}'),
                          _Badge(icon: Icons.timer, label: _controller.formattedRemaining),
                          _Badge(icon: Icons.favorite, label: 'Lives ${_controller.lives}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                      onPressed: _togglePause,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _handleBonusLifePurchase() async {
    final pauseManager = _pauseManager;
    pauseManager?.pause(PauseReason.hint);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need a boost?'),
        content: const Text('Watch a quick ad to earn an extra life (simulated).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Get life'),
          ),
        ],
      ),
    );
    pauseManager?.resume(PauseReason.hint);
    if (confirmed == true) {
      _controller.grantBonusLife();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bonus life added!')),
        );
      }
    }
  }

  int _initialLivesFor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.moderate:
        return 2;
      case DifficultyLevel.hard:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _SerpuzzleHud(
            level: _controller.level,
            score: _controller.score,
            timeRemaining: _controller.formattedRemaining,
            lives: _controller.lives,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bonus life',
            icon: const Icon(Icons.favorite_border),
            onPressed: _handleBonusLifePurchase,
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              icon: Icon(_controller.isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
            ),
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async => !_isOverlayBlocking, // block back while overlay active
        child: Stack(
          children: [
            // Game layer – blocked when overlay is active
            IgnorePointer(
              ignoring: _isOverlayBlocking,
              child: SerpuzzleGameScreen(
                key: _gameKey,
                controller: _controller,
              ),
            ),

            // Input shield above the game when paused/overlayed
            if (_isOverlayBlocking)
              const ModalBarrier(
                dismissible: false,
                color: Colors.transparent, // use Colors.black45 if you want a dim background
              ),
            if (_isOverlayBlocking)
              _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }
}

class _SerpuzzleHud extends StatelessWidget {
  const _SerpuzzleHud({
    required this.level,
    required this.score,
    required this.timeRemaining,
    required this.lives,
  });

  final int level;
  final int score;
  final String timeRemaining;
  final int lives;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium ??
        const TextStyle())
        .copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _StatusBadge(
          icon: Icons.flag,
          label: 'Level $level',
          labelStyle: labelStyle,
          color: theme.colorScheme.primary,
        ),
        _StatusBadge(
          icon: Icons.emoji_events,
          label: 'Score $score',
          labelStyle: labelStyle,
          color: theme.colorScheme.primary,
        ),
        _StatusBadge(
          icon: Icons.timer,
          label: timeRemaining,
          labelStyle: labelStyle,
          color: theme.colorScheme.primary,
        ),
        _StatusBadge(
          icon: Icons.favorite,
          label: 'Lives $lives',
          labelStyle: labelStyle,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.color,
  });


  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: labelStyle),
      backgroundColor:
      Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: theme.colorScheme.primary),
      label: Text(label, style: theme.textTheme.labelMedium),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}