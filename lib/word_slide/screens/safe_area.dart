//Y:\word_game_app_puzzle\lib\screens\safe_area.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_game_app/utils/pause_manager.dart';
import 'package:word_game_app/utils/score_uploader.dart';
import 'package:word_game_app/word_slide/models/alphabet_game.dart';
import 'package:word_game_app/word_slide/screens/game_screen.dart';
import 'package:word_game_app/word_slide/screens/settings_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Timer? _timer;
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

    game = AlphabetGame(widget.wordList);
    _remainingTime = widget.gameDuration;
    _startTimer();
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
    _pauseTimer();

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
    if (_timer != null || _remainingTime <= 0) {
      return;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_remainingTime <= 0) {
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
                      pauseManager.forceResume();
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

    return Scaffold(
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
              final pauseManager = Provider.of<PauseManager>(context, listen: false);
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
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
            if (pauseManager.isPaused &&
                pauseManager.pauseReason == PauseReason.manual)
              _buildPauseOverlay(context, pauseManager),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Provider.of<PauseManager>(context, listen: false)
        .removeListener(_onPauseStateChanged);
    _timer?.cancel();
    _bannerAd.dispose();
    super.dispose();
  }
}
