//Y:\word_game_app_puzzle\lib\screens\safe_area.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alphabet_game.dart';
import '../utils/score_uploader.dart';
import '../utils/pause_manager.dart';
import 'game_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  final GlobalKey<GameScreenState> _gameScreenKey = GlobalKey();
  int _adUsesThisMatch = 0;
  final int _maxAdUsesPerMatch = 2;
  late int moveCounter;
  List<String> correctWords = [];
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  late AlphabetGame game;
  late int _remainingTime;
  late Timer _timer;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    moveCounter = 1;
    _loadRewardedAd();

    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    pauseManager.addListener(_onPauseStateChanged);

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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

    game = AlphabetGame(widget.wordList);
    _remainingTime = widget.gameDuration;
    _startTimer();
  }

  void _onPauseStateChanged() {
    final pauseManager = Provider.of<PauseManager>(context, listen: false);
    if (pauseManager.isPaused) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
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

        (_gameScreenKey.currentState as dynamic)?.addHints(3);

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

  void onCorrectWord(String word) {
    setState(() {
      correctWords.add(word);
    });
  }

  void _endGame() {
    if (_timer.isActive) _timer.cancel();

    int safeMoveCounter = moveCounter == 0 ? 1 : moveCounter;
    int finalScore = (correctWords.length * 1000) ~/ safeMoveCounter;

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
                  itemCount: correctWords.length,
                  itemBuilder: (context, index) {
                    return Text(
                      "• ${correctWords[index]}",
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
                  pageBuilder: (_, __, ___) => SafeAreaScreen(
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
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  void _resumeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _endGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pauseManager = Provider.of<PauseManager>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Word Game',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: "Pause",
            onPressed: () {
              final pauseManager = Provider.of<PauseManager>(context, listen: false);
              pauseManager.pause(PauseReason.manual);

              showDialog(
                context: context,
                barrierDismissible: false,  // 🔒 disables outside-tap to dismiss
                builder: (context) => AlertDialog(
                  title: const Text('Game Paused'),
                  content: const Text("What would you like to do?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        pauseManager.resume(PauseReason.manual);
                      },
                      child: const Text('Resume'),
                    ),
                   TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // back to menu
                    },
                    child: const Text('Exit'),
                   ),
                  ],
                ),
              );

            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: IgnorePointer(
                ignoring: pauseManager.isPaused,
                child: GameScreen(
                key: _gameScreenKey,
                game: game,
                dictionary: widget.wordList,
                onCorrectWord: onCorrectWord,
                scoringOption: widget.scoringOption,
                onPauseToggle: () {
                  if (pauseManager.isPaused &&
                      pauseManager.pauseReason == PauseReason.manual) {
                    pauseManager.resume(PauseReason.manual);
                  } else {
                    pauseManager.pause(PauseReason.manual);
                  }
                },
                maxHints: 3,
                onRewardedAdRequest: _showRewardedAdForHints,
                adUsesThisMatch: _adUsesThisMatch,
                maxAdUsesPerMatch: _maxAdUsesPerMatch,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(2),
                color: Colors.white60,
                child: ListView.builder(
                  itemCount: correctWords.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2),
                        color: Colors.yellowAccent.shade100,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        correctWords[index],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
      ),
    );
  }

  @override
  void dispose() {
    Provider.of<PauseManager>(context, listen: false)
        .removeListener(_onPauseStateChanged);
    _timer.cancel();
    _bannerAd.dispose();
    super.dispose();
  }
}

