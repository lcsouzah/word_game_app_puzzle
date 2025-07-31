//main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/pause_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/mode_selection_screen.dart';
import 'utils/word_category.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PauseManager()),
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


Future<List<String>> loadWordList(String path) async {
  try {
    final content = await rootBundle.loadString(path);
    return content
        .split('\n')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
  } catch (e) {
    debugPrint("Failed to load $path: $e");
    return [];
  }
}

Future<List<WordCategory>> loadCategories() async {
  final categories = <WordCategory>[];

  final definitions = [
    {'name': 'Dictionary', 'path': 'assets/dictionary/words.txt'},
    {'name': 'Food', 'path': 'assets/food/words.txt'},
    {'name': 'Animals', 'path': 'assets/animals/words.txt'},
    {'name': 'Fruits', 'path': 'assets/fruits/words.txt'},
    {'name': 'Body Parts', 'path': 'assets/bodyparts/words.txt'},
    {'name': 'Clothing', 'path': 'assets/clothing/words.txt'},
    {'name': 'Colors', 'path': 'assets/colors/words.txt'},
    {'name': 'Countries', 'path': 'assets/countries/words.txt'},
    {'name': 'Jobs', 'path': 'assets/jobs/words.txt'},
    {'name': 'Transportation', 'path': 'assets/transportation/words.txt'},
    {'name': 'Weather', 'path': 'assets/weather/words.txt'},
  ];

  for (var def in definitions) {
    try {
      final words = await loadWordList(def['path']!);
      categories.add(WordCategory(name: def['name']!, allWords: words));
    } catch (e) {
      debugPrint('Failed to load category ${def['name']}: $e');
    }
  }

  return categories;
}



