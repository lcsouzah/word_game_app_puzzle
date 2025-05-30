import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/word_category.dart';
import '../screens/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize(); // Ensure AdMob initializes properly

  try {
    List<WordCategory> categories = await loadCategories();
    List<String> easyWords = await loadWordList('assets/dictionary/words_easy.txt');
    List<String> moderateWords = await loadWordList('assets/dictionary/words_mod.txt');
    List<String> hardWords = await loadWordList('assets/dictionary/words_hard.txt');

    runApp(MyApp(
      categories: categories,
      easyWords: easyWords,
      moderateWords: moderateWords,
      hardWords: hardWords,
    ));
  } catch (e) {
    print("Error initializing app: $e");
  }
}

class MyApp extends StatefulWidget {
  final List<String> easyWords;
  final List<String> moderateWords;
  final List<String> hardWords;
  final List<WordCategory> categories;

  const MyApp({
    super.key,
    required this.categories,
    required this.easyWords,
    required this.moderateWords,
    required this.hardWords,
  });

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  void toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode, // Use the theme mode determined by toggle
      home: StartScreen(
        easyWords: widget.easyWords,
        moderateWords: widget.moderateWords,
        hardWords: widget.hardWords,
        categories: widget.categories,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

// ✅ Load word list safely
Future<List<String>> loadWordList(String path) async {
  try {
    final fileContents = await rootBundle.loadString(path);
    return fileContents
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  } catch (e) {
    print("Error loading file: $path, Error: $e");
    return [];
  }
}

// ✅ Load categories safely
Future<List<WordCategory>> loadCategories() async {
  List<Map<String, dynamic>> categoryDefinitions = [
    {'name': 'Dictionary', 'path': 'assets/dictionary/'},
    {'name': 'Food', 'path': 'assets/food/'},
  ];

  List<WordCategory> categories = [];
  for (var category in categoryDefinitions) {
    try {
      categories.add(WordCategory(
        name: category['name'],
        difficultyLevels: {
          'Easy': await loadWordList('${category['path']}words_easy.txt'),
          'Moderate': await loadWordList('${category['path']}words_mod.txt'),
          'Hard': await loadWordList('${category['path']}words_hard.txt'),
        },
      ));
    } catch (e) {
      print("Error loading category: ${category['name']}, Error: $e");
    }
  }
  return categories;
}
