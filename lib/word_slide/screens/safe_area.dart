//Y:\word_game_app_puzzle\lib\screens\safe_area.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:word_game_app/services/settings_screen.dart';
import 'package:word_game_app/services/settings_service.dart';
import 'package:word_game_app/utils/pause_manager.dart';
import 'package:word_game_app/utils/score_uploader.dart';
import 'package:word_game_app/utils/text_format.dart';
import 'package:word_game_app/word_slide/controllers/word_quest_controller.dart';
import 'package:word_game_app/word_slide/models/alphabet_game.dart';
import 'package:word_game_app/word_slide/screens/game_screen.dart';

class SafeAreaScreen extends StatefulWidget {
  final ScoringOption scoringOption;
  final int gameDuration;
  final List<String> wordList;
  final String difficulty;

  const SafeAreaScreen({
    super.key,
    required this.scoringOption,
    required this.gameDuration,
    required this.wordList,
    required this.difficulty,
  });

  @override
  SafeAreaScreenState createState() => SafeAreaScreenState();
}

class SafeAreaScreenState extends State<SafeAreaScreen> {
  int _adUsesThisMatch = 0;
  final int _maxAdUsesPerMatch = 2;
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  WordQuestController? _controller;
  late Future<void> _initialisation;
  late int _remainingTime;
  Timer? _timer;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _initialisation = _prepareGame();

    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    pauseManager.addListener(_onPauseStateChanged);

    _bannerAd = BannerAd(
      adUnitId: dotenv.env['BANNER_AD_UNIT_ID']!,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();

    _remainingTime = widget.gameDuration;

    if (pauseManager.isPaused) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _prepareGame() async {
    final filtered = await compute<_DictionaryPayload, List<String>>(
      _filterDictionary,
      _DictionaryPayload(words: widget.wordList, difficulty: widget.difficulty),
    );
    final alphabetGame = AlphabetGame(filtered);
    _controller = WordQuestController(
      game: alphabetGame,
      dictionary: filtered,
      scoringOption: widget.scoringOption,
      initialHints: 3,
    );
  }

  void _onPauseStateChanged() {
    if(!mounted) return;
    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    if (pauseManager.isPaused) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  void _resetPauseState() {
    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    pauseManager.forceResume();
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: dotenv.env['REWARDED_AD_UNIT_ID']!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
          _isAdLoading = false;
        },
      ),
    );
  }

  void _showRewardedAdForHints() {
    final pauseManager = Provider.of<PauseManager>(context, listen: false);

    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready. Try again later.')),
      );
      return;
    }

    pauseManager.pause(PauseReason.ad);
    pauseManager.pause(PauseReason.manual);

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        setState(() {
          _adUsesThisMatch++;
          pauseManager.forceResume();
          pauseManager.resume(PauseReason.ad);
        });

        _controller?.addHints(3);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+3 hints unlocked')),
        );
      },
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        pauseManager.resume(PauseReason.ad);
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        pauseManager.resume(PauseReason.ad);
        ad.dispose();
      },
    );

    _rewardedAd = null;
  }

  void _endGame() {
    if (_isGameOver) return;

    setState(() {
      _isGameOver = true;
    });
    _pauseTimer();

    final solvedWords = List<String>.from(_controller?.solvedWords.value ?? []);
    final moveCount = max(1, _controller?.moves.value ?? 1);
    final int finalScore =
    solvedWords.isEmpty ? 0 : (solvedWords.length * 1000) ~/ moveCount;

    submitScore(score: finalScore, difficulty: widget.difficulty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⏰ Time's Up!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🎯 You scored $finalScore points."),
            const SizedBox(height: 12),
            const Text(
              "✅ Words You Got Right:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: solvedWords.length,
                  itemBuilder: (context, index) {
                    return Text(
                      "• ${solvedWords[index]}",
                      style: const TextStyle(fontSize: 16),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  pageBuilder: (context, animation, secondaryAnimation) => SafeAreaScreen(
                    scoringOption: widget.scoringOption,
                    gameDuration: widget.gameDuration,
                    wordList: widget.wordList,
                    difficulty: widget.difficulty,
                  ),
                ),
              );
            },
            child: const Text("🔁 Play Again"),
          ),
          TextButton(
            onPressed: () {
              _resetPauseState();
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
            child: const Text("🏠 Back to Menu"),
          ),
        ],
      ),
    );
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _resumeTimer() {
    if (_timer != null || _remainingTime <= 0 || _isGameOver) {
      return;
    }
    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    if (pauseManager.pauseReason != PauseReason.none) {
      return;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_remainingTime <= 0 || _isGameOver) {
      return;
    }
    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    if (pauseManager.pauseReason != PauseReason.none) {
      _pauseTimer();
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _timer = null;
        _endGame();
      }
    });
  }

  Widget _buildPauseOverlay(BuildContext context, PauseManager pauseManager) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Paused',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The timer is paused. Tap resume when you are ready to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      pauseManager.resume(PauseReason.manual);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _resetPauseState();
                      _pauseTimer();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Exit to Menu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pauseManager = Provider.of<PauseManager>(context);
    final settings = context.watch<SettingsService>();


    return WillPopScope(
      onWillPop: () async => !_isGameOver,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text(
            'Word Game',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                final pauseManager =
                Provider.of<PauseManager>(context, listen: false);
                pauseManager.pause(PauseReason.manual);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ).then((_) {
                  if (!mounted) return;
                  pauseManager.resume(PauseReason.manual);
                });
              },
            ),
            IconButton(
              icon: Icon(
                pauseManager.isPaused &&
                    pauseManager.pauseReason == PauseReason.manual
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
              tooltip: pauseManager.isPaused &&
                  pauseManager.pauseReason == PauseReason.manual
                  ? 'Resume'
                  : 'Pause',
              onPressed: () {
                final pauseManager =
                Provider.of<PauseManager>(context, listen: false);
                if (pauseManager.isPaused &&
                    pauseManager.pauseReason == PauseReason.manual) {
                  pauseManager.resume(PauseReason.manual);
                } else {
                  pauseManager.pause(PauseReason.manual);
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<void>(
            future: _initialisation,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final controller = _controller;
              if (controller == null) {
                return const Center(child: Text('Failed to load game data'));
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: IgnorePointer(
                          ignoring: pauseManager.isPaused || _isGameOver,
                          child: ChangeNotifierProvider.value(
                            value: controller,
                            child: GameScreen(
                              onRewardedAdRequest: _showRewardedAdForHints,
                              adUsesThisMatch: _adUsesThisMatch,
                              maxAdUsesPerMatch: _maxAdUsesPerMatch,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          color: Colors.white60,
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable: controller.solvedWords,
                            builder: (context, words, _) {
                              if (words.isEmpty) {
                                return const Center(
                                  child: Text('Find words to fill your log!'),
                                );
                              }
                              return ListView.builder(
                                itemCount: words.length,
                                itemBuilder: (context, index) {
                                  final displayWord =
                                  _formatWordForDisplay(
                                    words[index],
                                    settings.useTitleCaseWords,
                                  );
                                  return Container(
                                    margin: const EdgeInsets.all(4.0),
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2),
                                      color: Colors.yellowAccent.shade100,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child: Text(
                                      displayWord,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Time Remaining: $_remainingTime seconds',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                      ),
                      if (_isAdLoaded)
                        Container(
                          alignment: Alignment.center,
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                    ],
                  ),
                  if (pauseManager.isPaused &&
                      pauseManager.pauseReason == PauseReason.manual)
                    _buildPauseOverlay(context, pauseManager),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resetPauseState();
    Provider.of<PauseManager>(context, listen: false)
        .removeListener(_onPauseStateChanged);
    _timer?.cancel();
    _bannerAd.dispose();
    _controller?.dispose();
    super.dispose();
  }

  String _formatWordForDisplay(String word, bool useTitleCase) {
    if (word.isEmpty) {
      return word;
    }
    if (!useTitleCase) {
      return word.toUpperCase();
    }
    return titleCaseFirstOnly(word);
  }
}

class _DictionaryPayload {
  const _DictionaryPayload({
    required this.words,
    required this.difficulty,
  });

  final List<String> words;
  final String difficulty;
}

List<String> _filterDictionary(_DictionaryPayload payload) {
  final difficulty = payload.difficulty.toLowerCase();
  final maxLength = switch (difficulty) {
    'easy' => 5,
    'medium' => 7,
    'hard' => 10,
    _ => 12,
  };
  final unique = <String>{};
  for (final word in payload.words) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.length <= maxLength) {
      unique.add(trimmed.toUpperCase());
    }
  }
  return unique.toList(growable: false);
}