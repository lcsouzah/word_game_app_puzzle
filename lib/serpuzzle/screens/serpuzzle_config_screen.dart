import 'package:flutter/material.dart';
import 'package:word_game_app/serpuzzle/models/difficulty_level.dart';
import 'package:word_game_app/serpuzzle/screens/serpuzzle_safe_screen.dart';

class SerpuzzleConfigScreen extends StatefulWidget {
  const SerpuzzleConfigScreen({super.key});

  @override
  State<SerpuzzleConfigScreen> createState() => _SerpuzzleConfigScreenState();
}

class _SerpuzzleConfigScreenState extends State<SerpuzzleConfigScreen> {
  DifficultyLevel _difficulty = DifficultyLevel.easy;
  bool _centerStart = true;
  bool _wrapAround = false;
  static const int _gridSize = 8;

  static const List<String> _baseDictionary = [
    'CAT',
    'DOG',
    'BIRD',
    'FISH',
    'HORSE',
  ];

  int _maxWordLengthFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.moderate:
        return 4;
      case DifficultyLevel.hard:
        return 5;
    }
  }

  List<String> _dictionaryFor(DifficultyLevel level) {
    final maxLen = _maxWordLengthFor(level);
    return _baseDictionary.where((w) => w.length <= maxLen).toList();
  }

  Duration _moveDelayFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return const Duration(milliseconds: 500);
      case DifficultyLevel.moderate:
        return const Duration(milliseconds: 300);
      case DifficultyLevel.hard:
        return const Duration(milliseconds: 200);
    }
  }

  Duration _timeLimitFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return const Duration(minutes: 2);
      case DifficultyLevel.moderate:
        return const Duration(minutes: 1, seconds: 30);
      case DifficultyLevel.hard:
        return const Duration(minutes: 1);
    }
  }


  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SerpuzzleSafeScreen(
          gridSize: _gridSize,
          dictionary: _dictionaryFor(_difficulty),
          maxWordLength: _maxWordLengthFor(_difficulty),
          startCentered: _centerStart,
          moveDelay: _moveDelayFor(_difficulty),
          levelTimeLimit: _timeLimitFor(_difficulty),
          wrapAround: _wrapAround,
          difficulty: _difficulty,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _SerpuzzlePalette(theme);

    return Scaffold(
      appBar: AppBar(title: const Text('Serpuzzle Config')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.backgroundGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    top: -24,
                    child: Opacity(
                      opacity: 0.18,
                      child: _SerpuzzleSnakeIllustration(
                        color: palette.snakeAccent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -36,
                    bottom: -28,
                    child: Opacity(
                      opacity: 0.12,
                      child: _SerpuzzleSnakeIllustration(
                        color: palette.snakeShadow,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tune your serpent',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: palette.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adjust how the puzzle snake behaves before slithering into a new board.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Difficulty',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<DifficultyLevel>(
                          segments: const [
                            ButtonSegment(
                              value: DifficultyLevel.easy,
                              label: Text('Easy'),
                              icon: Icon(Icons.grass),
                            ),
                            ButtonSegment(
                              value: DifficultyLevel.moderate,
                              label: Text('Moderate'),
                              icon: Icon(Icons.terrain),
                            ),
                            ButtonSegment(
                              value: DifficultyLevel.hard,
                              label: Text('Hard'),
                              icon: Icon(Icons.local_fire_department),
                            ),
                          ],
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                  (states) => states.contains(MaterialState.selected)
                                  ? palette.segmentSelectedBackground
                                  : palette.segmentBackground,
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith(
                                  (states) => states.contains(MaterialState.selected)
                                  ? palette.segmentSelectedForeground
                                  : palette.segmentForeground,
                            ),
                            side: MaterialStateProperty.all(
                              BorderSide(color: palette.segmentBorder),
                            ),
                            elevation: MaterialStateProperty.resolveWith(
                                  (states) => states.contains(MaterialState.selected) ? 2 : 0,
                            ),
                          ),
                          selected: {_difficulty},
                          onSelectionChanged: (selection) {
                            if (selection.isNotEmpty) {
                              setState(() => _difficulty = selection.first);
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        _SerpuzzleToggleTile(
                          title: 'Start Centered',
                          subtitle: 'Spawn the snake head in the centre of the grid.',
                          value: _centerStart,
                          onChanged: (val) => setState(() => _centerStart = val),
                          icon: Icons.center_focus_strong,
                          palette: palette,
                        ),
                        const SizedBox(height: 16),
                        _SerpuzzleToggleTile(
                          title: 'Wrap Around',
                          subtitle: 'Allow the snake to exit one edge and appear on the opposite side.',
                          value: _wrapAround,
                          onChanged: (val) => setState(() => _wrapAround = val),
                          icon: Icons.loop,
                          palette: palette,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.ctaBackground,
                              foregroundColor: palette.ctaForeground,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start adventure'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SerpuzzlePalette {
  _SerpuzzlePalette(ThemeData theme) : brightness = theme.brightness;

  final Brightness brightness;

  Color get primaryText => brightness == Brightness.dark
      ? Colors.white
      : Colors.blueGrey.shade900;

  Color get secondaryText => brightness == Brightness.dark
      ? Colors.blueGrey.shade100
      : Colors.blueGrey.shade700;

  Color get segmentSelectedBackground => brightness == Brightness.dark
      ? Colors.greenAccent.shade400.withValues(alpha: 0.32)
      : Colors.greenAccent.shade200.withValues(alpha: 0.65);

  Color get segmentBackground => brightness == Brightness.dark
      ? Colors.blueGrey.shade800.withValues(alpha: 0.6)
      : Colors.blueGrey.shade200.withValues(alpha: 0.6);

  Color get segmentSelectedForeground => brightness == Brightness.dark
      ? Colors.greenAccent.shade100
      : Colors.blueGrey.shade900;

  Color get segmentForeground => brightness == Brightness.dark
      ? Colors.blueGrey.shade100
      : Colors.white;

  Color get segmentBorder => brightness == Brightness.dark
      ? Colors.greenAccent.shade400.withValues(alpha: 0.5)
      : Colors.blueGrey.shade400.withValues(alpha: 0.7);

  List<Color> get backgroundGradient => brightness == Brightness.dark
      ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
      : [Colors.blueGrey.shade100, Colors.blueGrey.shade400];

  Color get snakeAccent => brightness == Brightness.dark
      ? Colors.greenAccent.shade400
      : Colors.deepOrange.shade300;

  Color get snakeShadow => brightness == Brightness.dark
      ? Colors.blueGrey.shade600
      : Colors.greenAccent.shade200;

  Color get toggleActiveBackground => brightness == Brightness.dark
      ? Colors.greenAccent.shade400.withValues(alpha: 0.3)
      : Colors.greenAccent.shade100.withValues(alpha: 0.5);

  Color get toggleInactiveBackground => brightness == Brightness.dark
      ? Colors.blueGrey.shade800.withValues(alpha: 0.7)
      : Colors.blueGrey.shade100.withValues(alpha: 0.6);

  Color get toggleActiveBorder => brightness == Brightness.dark
      ? Colors.greenAccent.shade400
      : Colors.greenAccent.shade400.withValues(alpha: 0.8);

  Color get toggleInactiveBorder => brightness == Brightness.dark
      ? Colors.blueGrey.shade600
      : Colors.blueGrey.shade300;

  Color get toggleActiveIcon => brightness == Brightness.dark
      ? Colors.black87
      : Colors.blueGrey.shade900;

  Color get toggleInactiveIcon => brightness == Brightness.dark
      ? Colors.blueGrey.shade200
      : Colors.blueGrey.shade500;

  Color get toggleSecondaryText => brightness == Brightness.dark
      ? Colors.blueGrey.shade100
      : Colors.blueGrey.shade700;

  Color get toggleShadow => brightness == Brightness.dark
      ? Colors.black45
      : Colors.black26;

  Color get ctaBackground => brightness == Brightness.dark
      ? Colors.greenAccent.shade400
      : Colors.deepOrange.shade400;

  Color get ctaForeground => brightness == Brightness.dark
      ? Colors.black
      : Colors.white;

  Color get switchActiveTrack => brightness == Brightness.dark
      ? Colors.greenAccent.shade200.withValues(alpha: 0.5)
      : Colors.greenAccent.shade200;

  Color get switchInactiveTrack => brightness == Brightness.dark
      ? Colors.blueGrey.shade700
      : Colors.blueGrey.shade300;

  Color get switchInactiveThumb => brightness == Brightness.dark
      ? Colors.blueGrey.shade200
      : Colors.white;

  Color get switchActiveThumb => brightness == Brightness.dark
      ? Colors.black
      : Colors.blueGrey.shade900;
}

class _SerpuzzleToggleTile extends StatelessWidget {
  const _SerpuzzleToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final _SerpuzzlePalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: value
                ? palette.toggleActiveBackground
                : palette.toggleInactiveBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value
                  ? palette.toggleActiveBorder
                  : palette.toggleInactiveBorder,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.toggleShadow,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: value
                      ? palette.toggleActiveBorder.withValues(alpha: 0.3)
                      : palette.toggleInactiveBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: value
                      ? palette.toggleActiveIcon
                      : palette.toggleInactiveIcon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.toggleSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: palette.switchActiveThumb,
                inactiveThumbColor: palette.switchInactiveThumb,
                inactiveTrackColor: palette.switchInactiveTrack,
                activeTrackColor: palette.switchActiveTrack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SerpuzzleSnakeIllustration extends StatelessWidget {
  const _SerpuzzleSnakeIllustration({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SerpuzzleSnakePainter(color),
      size: const Size(220, 160),
    );
  }
}

class _SerpuzzleSnakePainter extends CustomPainter {
  _SerpuzzleSnakePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.12;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.05, height * 0.75);
    path.quadraticBezierTo(width * 0.25, height * 0.45, width * 0.42, height * 0.7);
    path.quadraticBezierTo(width * 0.6, height * 0.95, width * 0.72, height * 0.6);
    path.quadraticBezierTo(width * 0.82, height * 0.25, width * 0.94, height * 0.38);

    canvas.drawPath(path, bodyPaint);

    final headPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final headCenter = Offset(width * 0.94, height * 0.38);
    canvas.drawCircle(headCenter, size.shortestSide * 0.12, headPaint);

    final eyePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final eyeOffset = Offset(size.shortestSide * 0.03, -size.shortestSide * 0.02);
    canvas
      ..drawCircle(headCenter + eyeOffset, size.shortestSide * 0.03, eyePaint)
      ..drawCircle(headCenter + eyeOffset, size.shortestSide * 0.015, pupilPaint);

    final tonguePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final tonguePath = Path()
      ..moveTo(headCenter.dx + size.shortestSide * 0.08, headCenter.dy)
      ..lineTo(headCenter.dx + size.shortestSide * 0.14, headCenter.dy - size.shortestSide * 0.015)
      ..lineTo(headCenter.dx + size.shortestSide * 0.14, headCenter.dy + size.shortestSide * 0.015)
      ..close();
    canvas.drawPath(tonguePath, tonguePaint);
  }

  @override
  bool shouldRepaint(covariant _SerpuzzleSnakePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}