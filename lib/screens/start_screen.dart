//start_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import foundation for describeEnum

import '../utils/sound_manager.dart';
import '../screens/safe_area.dart';
import '../utils/word_category.dart';
import '../models/alphabet_game.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:games_services/games_services.dart'; // Import Game Services





enum DifficultyLevel {
  Easy,
  Moderate,
  Hard,
}
String? _selectedCategory;
List<WordCategory> _categories = [];


class StartScreen extends StatefulWidget {
  final List<String> easyWords;
  final List<String> moderateWords;
  final List<String> hardWords;
  final List<WordCategory> categories;
  final VoidCallback toggleTheme; // Add this line

  const StartScreen({
    super.key,
    required this.easyWords,
    required this.moderateWords,
    required this.hardWords,
    required this.categories,
    required this.toggleTheme, // Update this line
  });

  @override
  _StartScreenState createState() => _StartScreenState();
}


class _StartScreenState extends State<StartScreen> {
  // ... existing properties and methods ...
  String? _selectedCategoryName;

  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  DifficultyLevel _selectedDifficulty = DifficultyLevel.Easy;


  ScoringOption _scoringOption = ScoringOption.Horizontal;


  late int _selectedTime = 180; // Default to 3 minutes


  Widget _buildScoringOption(ScoringOption option) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Radio<ScoringOption>(
            value: option,
            groupValue: _scoringOption,
            onChanged: _handleRadioValueChanged,
          ),
          Flexible( // This will prevent text from breaking into a new line
            child: Text(
              describeEnum(option), // Assuming describeEnum is properly imported//
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _safeSignIn(); // // 👈 GAME SERVICE silent sign-in here


    if (widget.categories.isNotEmpty) {
      _selectedCategoryName = widget.categories.first.name;
    }

    _initBannerAd();

    // SoundManager.preloadSound(("tileMove"), "sounds/tile_move.mp3");
    // Preload other sounds as needed
  }

  void _safeSignIn() async {
    try {
      await GamesServices.signIn();
    } catch (e) {
      if (kDebugMode) print("Sign-in failed: $e");
    }
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2001371236360532/6515690897',
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
  }

  void _handleRadioValueChanged(ScoringOption? value) {
    if (value != null) {
      setState(() {
        _scoringOption = value;
      });
    }
  }

  void _startGame() {
    List<String> selectedWordList = _getSelectedWordList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SafeAreaScreen(
              scoringOption: _scoringOption,
              gameDuration: _selectedTime,
              wordList: selectedWordList,
              difficulty: _selectedDifficulty.name.toLowerCase(),
            ),
      ),
    );
  }

  List<String> _getSelectedWordList() {
    switch (_selectedDifficulty) {
      case DifficultyLevel.Moderate:
        return widget.moderateWords;
      case DifficultyLevel.Hard:
        return widget.hardWords;
      default:
        return widget.easyWords;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Start Screen'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.brightness_6), // or Icons.brightness_3 for dark mode icon
            onPressed: widget.toggleTheme, // Use the toggleTheme function
          ),
            IconButton(
            icon: Icon(
              SoundManager.isMuted() ? Icons.volume_off : Icons.volume_up,
            ),
            onPressed: () {
              setState(() {
                SoundManager.toggleMute();
              });
            },
          ),
        ],
      ),

      body: Column(

        //mainAxisAlignment: MainAxisAlignment.center,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[


                DropdownButton<String>(
                  value: _selectedCategoryName,
                  icon: const Icon(Icons.arrow_downward), // Optional icon
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple), // Customize your style
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoryName = newValue;
                    });
                  },
                  items: widget.categories.map<DropdownMenuItem<String>>((WordCategory category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.name),
                    );
                  }).toList(),
                ),


                // Updated difficulty selector with new styling
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: DifficultyLevel.values.map((level) {
                    String label = level.toString().split('.').last;
                    return ChoiceChip(
                      backgroundColor: Colors.deepPurple.shade200,
                      shadowColor: Colors.red,
                      selectedShadowColor: Colors.greenAccent,
                      elevation: 15,
                      label: Text(label),
                      selected: _selectedDifficulty == level,
                      selectedColor: Colors.deepPurple.shade300, // Your theme color here
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedDifficulty = level;
                        });
                      },
                    );
                  }).toList(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric( vertical: 30)
                ),

                 Text('SELECT SCORING OPTION:',
                  style: TextStyle(
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],

                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    // decorationThickness: 100,
                  ),
                  ),

                // Updated scoring option selector with RadioListTile
                // Scoring Option Selector laid out horizontally
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ScoringOption.values.map((option) {
                    return _buildScoringOption(option);
                  }).toList(),
                ),
                // Time selector remains the same
                DropdownButton<int>(
                  value: _selectedTime,
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _selectedTime = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem<int>(value: 180, child: Text('3 Minutes')),
                    DropdownMenuItem<int>(value: 240, child: Text('4 Minutes')),
                    DropdownMenuItem<int>(value: 300, child: Text('5 Minutes')),
                  ],
                ),
                ElevatedButton(
                  onPressed: _startGame,
                  child: const Text('Start Game',
                    
                  ),
                  // Add styling for the button as per new UI theme
                ),



                ElevatedButton(
                  onPressed: () async {
                    String leaderboardId;
                    switch (_selectedDifficulty) {
                      case DifficultyLevel.Easy:
                        leaderboardId = 'CgkIr_H04_cJEAIQAg';
                        break;
                      case DifficultyLevel.Moderate:
                        leaderboardId = 'CgkIr_H04_cJEAIQAw';
                        break;
                      case DifficultyLevel.Hard:
                        leaderboardId = 'CgkIr_H04_cJEAIQBA';
                        break;
                    }

                    try {
                      await GamesServices.showLeaderboards(
                        androidLeaderboardID: leaderboardId,
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Failed to open leaderboard: $e');
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Leaderboard not available. Check connection or Google Play Games setup.")),
                      );
                    }
                  },
                  child: const Text('View Leaderboard'),
                ),

              ],
            ),
          ),
          if (_isAdLoaded) // Show ad only if loaded
            Container(
              alignment: Alignment.center,
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}