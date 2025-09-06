import 'dart:math';
import 'package:flutter/material.dart';

/// Direction values used by [SwipeDetector].
enum DirectionEnum { up, down, left, right }

/// Simple gesture detector that converts a swipe into a [DirectionEnum].
class SwipeDetector extends StatelessWidget {
  final Widget child;
  final void Function(DirectionEnum) onSwipe;

  const SwipeDetector({super.key, required this.child, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dx.abs() > velocity.dy.abs()) {
          onSwipe(velocity.dx > 0 ? DirectionEnum.right : DirectionEnum.left);
        } else {
          onSwipe(velocity.dy > 0 ? DirectionEnum.down : DirectionEnum.up);
        }
      },
      child: child,
    );
  }
}

/// Basic tile used in the Serpuzzle grid.
class SerpuzzleTile extends StatelessWidget {
  final String letter;
  final bool highlighted;

  const SerpuzzleTile({super.key, required this.letter, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: highlighted ? Colors.yellow : Colors.blueGrey.shade700,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}

/// Overlay widget that paints the snake body on top of the grid.
class SerpuzzleSnakeBody extends StatelessWidget {
  final List<int> positions;
  final int gridSize;

  const SerpuzzleSnakeBody({super.key, required this.positions, required this.gridSize});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = constraints.maxWidth / gridSize;
        return Stack(
          children: positions.map((index) {
            final row = index ~/ gridSize;
            final col = index % gridSize;
            return Positioned(
              left: col * tileSize,
              top: row * tileSize,
              width: tileSize,
              height: tileSize,
              child: Container(
                color: Colors.green.withOpacity(0.3),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Very small word-matching engine. Checks if the collected letters
/// form any word in the provided [dictionary].
class WordMatchEngine {
  final Set<String> dictionary;

  WordMatchEngine(List<String> words)
      : dictionary = words.map((e) => e.toUpperCase()).toSet();

  bool matches(String letters) => dictionary.contains(letters.toUpperCase());
}

/// Serpuzzle game screen showing the grid and handling swipe input.
class SerpuzzleGameScreen extends StatefulWidget {
  final int gridSize;
  final List<String> dictionary;

  const SerpuzzleGameScreen({super.key, required this.gridSize, required this.dictionary});

  @override
  State<SerpuzzleGameScreen> createState() => _SerpuzzleGameScreenState();
}

class _SerpuzzleGameScreenState extends State<SerpuzzleGameScreen> {
  late List<String> _letters;
  late List<int> _snake;
  final Set<int> _matched = {};
  int _score = 0;
  late WordMatchEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = WordMatchEngine(widget.dictionary);
    _initBoard();
  }

  void _initBoard() {
    final rand = Random();
    _letters = List.generate(widget.gridSize * widget.gridSize,
            (_) => String.fromCharCode(65 + rand.nextInt(26)));
    final start = (widget.gridSize ~/ 2) * widget.gridSize + widget.gridSize ~/ 2;
    _snake = [start];
  }

  void _onSwipe(DirectionEnum direction) {
    final head = _snake.last;
    int row = head ~/ widget.gridSize;
    int col = head % widget.gridSize;
    switch (direction) {
      case DirectionEnum.up:
        row -= 1;
        break;
      case DirectionEnum.down:
        row += 1;
        break;
      case DirectionEnum.left:
        col -= 1;
        break;
      case DirectionEnum.right:
        col += 1;
        break;
    }
    if (row < 0 || col < 0 || row >= widget.gridSize || col >= widget.gridSize) {
      return; // out of bounds
    }
    final newIndex = row * widget.gridSize + col;
    if (_snake.contains(newIndex)) return; // don't allow self-collision
    setState(() {
      _snake.add(newIndex);
      _validate();
    });
  }

  void _validate() {
    final letters = _snake.map((i) => _letters[i]).join();
    if (_engine.matches(letters)) {
      _matched.addAll(_snake);
      _score += letters.length;
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          for (final index in _matched) {
            _letters[index] = _randomLetter();
          }
          _matched.clear();
          _snake = [_snake.last];
        });
      });
    }
  }

  String _randomLetter() {
    final rand = Random();
    return String.fromCharCode(65 + rand.nextInt(26));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Score: $_score')),
      body: Center(
        child: SwipeDetector(
          onSwipe: _onSwipe,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridSize,
                  ),
                  itemCount: _letters.length,
                  itemBuilder: (context, index) {
                    final highlight = _matched.contains(index);
                    return SerpuzzleTile(
                      letter: _letters[index],
                      highlighted: highlight,
                    );
                  },
                ),
                SerpuzzleSnakeBody(
                  positions: _snake,
                  gridSize: widget.gridSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}