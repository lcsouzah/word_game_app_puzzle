import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alphabet_game.dart';
import 'game_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';



class SafeAreaScreen extends StatefulWidget {
  final ScoringOption scoringOption;
  final int gameDuration;
  final List<String> wordList;

  const SafeAreaScreen({
    super.key,
    required this.scoringOption,
    required this.gameDuration,
    required this.wordList,
  });

  @override
  _SafeAreaScreenState createState() => _SafeAreaScreenState();
}



class _SafeAreaScreenState extends State<SafeAreaScreen> {
  List<String> correctWords = [];
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  late AlphabetGame game;
  late int _remainingTime;
  late Timer _timer;


  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2001371236360532/6515690897', // Replace with your ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Handle the error
          ad.dispose();
        },
      ),
    )..load();
    game = AlphabetGame(widget.wordList);
    _remainingTime = widget.gameDuration;
    _startTimer();
  }


  void onCorrectWord(String word) {
    addCorrectWord(word);
  }


  void addCorrectWord(String word) {
    setState(() {
      correctWords.add(word);
    });
  }


  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          // Game over, navigate to a new screen or perform game over actions.
          _timer.cancel();
          // For now, let's navigate back to the start screen when the timer reaches 0.
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Word Game',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3, // Adjust flex to manage space
              child: GameScreen(
                game: game,
                dictionary: widget.wordList,
                onCorrectWord: onCorrectWord,
                scoringOption: widget.scoringOption,
              ),
            ),
            // List of correct words with updated styling
            Expanded(
              flex: 1, // Adjust flex to manage space
              child: Container(
                padding: const EdgeInsets.all(2),
                color: Colors.white60, // New background color for correct words list
                child: ListView.builder(
                  itemCount: correctWords.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                        ),
                        color: Colors.yellowAccent.shade100, // Individual item background color
                        borderRadius: BorderRadius.circular(5.0), // Rounded corners for ListTile
                      ),
                      child: Text(
                        correctWords[index],
                        style: const TextStyle(
                          fontSize: 18, // Larger font size for correct words
                          color: Colors.black, // Text color for correct words
                          fontWeight: FontWeight.bold, // Bold text style
                        ),
                        textAlign: TextAlign.center, // Center align text
                      ),
                    );
                  },
                ),
              ),
            ),
            // Time remaining and ads container unchanged
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
}









