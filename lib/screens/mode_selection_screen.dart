// Y:\word_game_app_puzzle\lib\screens\mode_selection_screen.dart


import 'package:flutter/material.dart';
import 'package:word_game_app/services/category_loader.dart';
import 'package:word_game_app/utils/word_category.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_config_screen.dart';
import 'package:word_game_app/word_slide/ui/screens/start_screen.dart';
import 'package:word_game_app/word_slide/ui/screens/store_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  final VoidCallback toggleTheme;

  const ModeSelectionScreen({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mode_select_background.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StoreScreenProvider(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront),
                  label: const Text('Store'),
                ),
              ),
            ),
          ),

// Word Slide button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.6175,
            left: MediaQuery.of(context).size.width * 0.1,
            width: MediaQuery.of(context).size.width * 0.8,
            height: 77,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                highlightColor: Colors.deepPurple.withValues(alpha: 0.2),
                onTap: () async {
                  final List<WordCategory> categories = await loadCategories();
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StartScreen(
                        categories: categories,
                        toggleTheme: toggleTheme,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

// Serpuzzle button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.746,
            left: MediaQuery.of(context).size.width * 0.1,
            width: MediaQuery.of(context).size.width * 0.8,
            height: 77,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.tealAccent.withValues(alpha: 0.3),
                highlightColor: Colors.teal.withValues(alpha: 0.2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SerpuzzleConfigScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

