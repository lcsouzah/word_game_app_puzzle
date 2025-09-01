//main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/pause_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/mode_selection_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/ad_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Load environment variables from .env file
  dotenv.mergeWith({
    if (const String.fromEnvironment('BANNER_AD_UNIT_ID').isNotEmpty)
      'BANNER_AD_UNIT_ID': const String.fromEnvironment('BANNER_AD_UNIT_ID'),
    if (const String.fromEnvironment('REWARDED_AD_UNIT_ID').isNotEmpty)
      'REWARDED_AD_UNIT_ID': const String.fromEnvironment('REWARDED_AD_UNIT_ID'),
    if (const String.fromEnvironment('EASY_LEADERBOARD_ID').isNotEmpty)
      'EASY_LEADERBOARD_ID': const String.fromEnvironment('EASY_LEADERBOARD_ID'),
    if (const String.fromEnvironment('MODERATE_LEADERBOARD_ID').isNotEmpty)
      'MODERATE_LEADERBOARD_ID': const String.fromEnvironment('MODERATE_LEADERBOARD_ID'),
    if (const String.fromEnvironment('HARD_LEADERBOARD_ID').isNotEmpty)
      'HARD_LEADERBOARD_ID': const String.fromEnvironment('HARD_LEADERBOARD_ID'),
  });
  await MobileAds.instance.initialize();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PauseManager()),
        Provider(create: (_) => AdService()),
        // other providers can be added here
      ],
      child: const MyApp(),
    ),
  );
}




class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Quest Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ModeSelectionScreen(toggleTheme: toggleTheme), // <-- NEW ENTRY SCREEN
    );
  }
}






