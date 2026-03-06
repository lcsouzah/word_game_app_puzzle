import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/cosmetic_manager.dart';
import '../../services/game_feedback_service.dart';
import '../ui/theme/board_theme.dart';
import 'alphabet_game.dart';
import 'game_config.dart';


class TileVisualState {
  final String letter;
  final bool highlighted;
  final bool disappearing;
  final TileHighlightKind highlightKind;


  const TileVisualState({
    required this.letter,
    required this.highlighted,
    required this.disappearing,
    required this.highlightKind,
  });

  TileVisualState copyWith({
    String? letter,
    bool? highlighted,
    bool? disappearing,
    TileHighlightKind? highlightKind,
  }) {
    return TileVisualState(
      letter: letter ?? this.letter,
      highlighted: highlighted ?? this.highlighted,
      disappearing: disappearing ?? this.disappearing,
      highlightKind: highlightKind ?? this.highlightKind,
    );
  }
}

class ScorePopup {
  const ScorePopup({
    required this.points,
    required this.gridX,
    required this.gridY,
    required this.isWord,
  });

  final int points;
  final int gridX;
  final int gridY;
  final bool isWord;
}

class WordQuestController extends ChangeNotifier {
  WordQuestController({
    required this.game,
    required List<String> dictionary,
    required this.scoringOption,
    required this.difficulty,
    int initialHints = 3,
  })  : _dictionary = List.unmodifiable(dictionary),
        hintsRemaining = ValueNotifier<int>(initialHints),
        tiles = List<ValueNotifier<TileVisualState>>.generate(
          game.letters.length,
              (index) => ValueNotifier<TileVisualState>(
            TileVisualState(
              letter: game.letters[index],
              highlighted: false,
              disappearing: false,
              highlightKind: TileHighlightKind.none,
            ),
          ),
        );

  final AlphabetGame game;
  final DifficultyLevel difficulty;
  final ScoringOption scoringOption;
  final List<String> _dictionary;

  final List<ValueNotifier<TileVisualState>> tiles;
  final ValueNotifier<int> moves = ValueNotifier<int>(0);
  final ValueNotifier<int> hintsRemaining;
  final ValueNotifier<List<String>> solvedWords =
  ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<ScorePopup?> scorePopup =
  ValueNotifier<ScorePopup?>(null);
  final ValueNotifier<int> pulseTicker = ValueNotifier<int>(0);
  final ValueNotifier<bool> isAnimating = ValueNotifier<bool>(false);

  Completer<void>? _hintCompleter;
  CosmeticManager? _cosmeticManager;

  void attachCosmeticManager(CosmeticManager manager) {
    _cosmeticManager = manager;
  }

  Future<void> onTileTapped(int index) async {
    if (isAnimating.value) return;
    final previousEmptyIndex = game.emptyTileIndex;
    final moved = game.moveTile(index);
    if (!moved) return;

    _updateLetter(previousEmptyIndex);
    _updateLetter(index);

    moves.value = moves.value + 1;
    unawaited(GameFeedbackService.onTileMove());
    await _evaluateBoard();
  }

  Future<void> _evaluateBoard() async {
    final payload = _WordCheckPayload(
      letters: List<String>.from(game.letters),
      dictionary: _dictionary,
      scoringOption: scoringOption,
    );
    final result = await compute<_WordCheckPayload, _WordCheckResult?>(
      _findCompletedWord,
      payload,
    );
    if (result == null || result.indices.isEmpty) {
      return;
    }

    isAnimating.value = true;
    solvedWords.value = List<String>.from(solvedWords.value)..add(result.word);

    final points = max(50, result.word.length * 25);
    _emitScorePopup(result.indices, points);
    _triggerBoardPulse();

    await _animateSolvedWord(result.indices);

    game.clearWord();
    game.generateNewLetters();
    for (int i = 0; i < tiles.length; i++) {
      _updateLetter(i);
    }

    isAnimating.value = false;
    unawaited(GameFeedbackService.onCorrectWord());
  }

  Future<void> _animateSolvedWord(List<int> indices) async {
    for (int i = 0; i < indices.length; i++) {
      final idx = indices[i];
      final notifier = tiles[idx];
      notifier.value = notifier.value.copyWith(
        highlighted: true,
        highlightKind: TileHighlightKind.solved,
      );
      await Future.delayed(const Duration(milliseconds: 110));
    }

    await Future.delayed(const Duration(milliseconds: 140));

    for (final idx in indices) {
      final notifier = tiles[idx];
      notifier.value = notifier.value.copyWith(
        highlighted: false,
        disappearing: true,
      );
      await Future.delayed(const Duration(milliseconds: 70));
    }

    await Future.delayed(const Duration(milliseconds: 180));

    for (final idx in indices) {
      final notifier = tiles[idx];
      notifier.value = notifier.value.copyWith(
        disappearing: false,
        highlighted: false,
        highlightKind: TileHighlightKind.none,
      );
    }
  }

  void _emitScorePopup(List<int> indices, int points) {
    final average = indices
        .map((i) => Offset((i % 4).toDouble(), (i ~/ 4).toDouble()))
        .fold<Offset>(Offset.zero, (sum, value) => sum + value) /
        indices.length.toDouble();
    scorePopup.value = ScorePopup(
      points: points,
      gridX: average.dx.round(),
      gridY: average.dy.round(),
      isWord: true,
    );
  }

  void _triggerBoardPulse() {
    pulseTicker.value = pulseTicker.value + 1;
  }

  Future<bool> showHint({
    Duration display = const Duration(milliseconds: 850),
  }) async {
    if (isAnimating.value || hintsRemaining.value <= 0) {
      return false;
    }
    if (moves.value <= 0) {
      // Don't consume hints before the player has interact with the board.
      _signalNoHintAvailable();
      return false;
    }
    if (_hintCompleter != null && !_hintCompleter!.isCompleted) {
      await _hintCompleter!.future;
    }

    final payload = _HintPayload(
      letters: List<String>.from(game.letters),
      dictionary: _dictionary,
    );
    final hintResult = await compute<_HintPayload, _HintResult>(
      _findHintIndices,
      payload,
    );
    final indices = hintResult.indices;
    final bestScore = hintResult.bestScore;
    if (indices.isEmpty) {
      _signalNoHintAvailable();
      return false;
    }

    List<int> hintTargets = const <int>[];
    switch (difficulty) {
      case DifficultyLevel.easy:
        hintTargets = indices;
        break;
      case DifficultyLevel.moderate:
        final maxLen = indices.length;
        final cap = maxLen <= 2 ? maxLen : maxLen - 1;
        final hintLen = bestScore <= 0
            ? 0
            : (bestScore + 1).clamp(1, cap);
        hintTargets =
            hintLen > 0 ? indices.take(hintLen).toList() : const <int>[];
        break;
      case DifficultyLevel.hard:
        if (bestScore <= 0 || bestScore >= indices.length) {
          hintTargets = const <int>[];
        } else {
          hintTargets = <int>[indices[bestScore]];
        }
        break;
    }

    if (hintTargets.isEmpty) {
      _signalNoHintAvailable();
      return false;
    }

    hintsRemaining.value = hintsRemaining.value - 1;

    _hintCompleter = Completer<void>();
    final cosmetics = _cosmeticManager;
    if (cosmetics != null) {
      final targets = hintTargets.map(_indexToCoord).toSet();
      if (targets.isNotEmpty) {
        cosmetics.beginHint(targets);
      }
    }
    try {
      for (final idx in hintTargets) {
        final notifier = tiles[idx];
        notifier.value = notifier.value.copyWith(
          highlighted: true,
          highlightKind: TileHighlightKind.hint,
        );
      }
      await Future.delayed(display);
      for (final idx in hintTargets) {
        final notifier = tiles[idx];
        notifier.value = notifier.value.copyWith(
          highlighted: false,
          highlightKind: TileHighlightKind.none,
        );
      }
      return true;
    } finally {
      _cosmeticManager?.endHint();
      _hintCompleter?.complete();
      _hintCompleter = null;
    }
  }

  void _signalNoHintAvailable() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia) {
      unawaited(HapticFeedback.lightImpact());
    }
  }


  void addHints(int amount) {
    hintsRemaining.value = hintsRemaining.value + amount;
  }

  void _updateLetter(int index) {
    final notifier = tiles[index];
    notifier.value = notifier.value.copyWith(
      letter: game.letters[index],
      highlighted: false,
      disappearing: false,
      highlightKind: TileHighlightKind.none,
    );
  }


  @override
  void dispose() {
    for (final notifier in tiles) {
      notifier.dispose();
    }
    moves.dispose();
    hintsRemaining.dispose();
    solvedWords.dispose();
    scorePopup.dispose();
    pulseTicker.dispose();
    isAnimating.dispose();
    super.dispose();
  }
}

class _WordCheckPayload {
  const _WordCheckPayload({
    required this.letters,
    required this.dictionary,
    required this.scoringOption,
  });

  final List<String> letters;
  final List<String> dictionary;
  final ScoringOption scoringOption;
}

class _WordCheckResult {
  const _WordCheckResult({required this.word, required this.indices});

  final String word;
  final List<int> indices;
}

_WordCheckResult? _findCompletedWord(_WordCheckPayload payload) {
  final List<_OrientationCheck> checks = switch (payload.scoringOption) {
    ScoringOption.horizontal => const [
      _OrientationCheck(horizontal: true),
    ],
    ScoringOption.vertical => const [
      _OrientationCheck(horizontal: false),
    ],
    ScoringOption.both => const [
      _OrientationCheck(horizontal: true),
      _OrientationCheck(horizontal: false),
    ],
  };

  for (final check in checks) {
    final word = check.horizontal
        ? _buildHorizontalWord(payload.letters)
        : _buildVerticalWord(payload.letters);
    if (word.isEmpty) continue;
    if (!payload.dictionary.contains(word)) continue;

    final indices = check.horizontal
        ? _collectHorizontalIndices(payload.letters, word)
        : _collectVerticalIndices(payload.letters, word);
    if (indices.isNotEmpty) {
      return _WordCheckResult(word: word, indices: indices);
    }
  }
  return null;
}

class _OrientationCheck {
  const _OrientationCheck({required this.horizontal});
  final bool horizontal;
}

String _buildHorizontalWord(List<String> letters) {
  final buffer = StringBuffer();
  for (final letter in letters) {
    if (letter.trim().isEmpty) break;
    buffer.write(letter);
  }
  return buffer.toString();
}

String _buildVerticalWord(List<String> letters) {
  const gridSize = 4;
  final buffer = StringBuffer();
  for (int col = 0; col < gridSize; col++) {
    for (int row = 0; row < gridSize; row++) {
      final index = row * gridSize + col;
      final letter = letters[index];
      if (letter.trim().isEmpty) return buffer.toString();
      buffer.write(letter);
    }
  }
  return buffer.toString();
}

List<int> _collectHorizontalIndices(List<String> letters, String word) {
  final indices = <int>[];
  var matchIndex = 0;
  for (int i = 0; i < letters.length && matchIndex < word.length; i++) {
    final letter = letters[i];
    if (letter.trim().isEmpty) break;
    if (letter == word[matchIndex]) {
      indices.add(i);
      matchIndex++;
    }
  }
  return indices.length == word.length ? indices : <int>[];
}

List<int> _collectVerticalIndices(List<String> letters, String word) {
  const gridSize = 4;
  final indices = <int>[];
  var matchIndex = 0;
  for (int col = 0; col < gridSize && matchIndex < word.length; col++) {
    for (int row = 0; row < gridSize && matchIndex < word.length; row++) {
      final index = row * gridSize + col;
      final letter = letters[index];
      if (letter.trim().isEmpty) return <int>[];
      if (letter == word[matchIndex]) {
        indices.add(index);
        matchIndex++;
      }
    }
  }
  return indices.length == word.length ? indices : <int>[];
}

TileCoord _indexToCoord(int index) {
  const gridSize = 4;
  return TileCoord(index ~/ gridSize, index % gridSize);
}


class _HintPayload {
  const _HintPayload({
    required this.letters,
    required this.dictionary,
  });

  final List<String> letters;
  final List<String> dictionary;
}

class _HintResult {
  const _HintResult({required this.indices, required this.bestScore});

  final List<int> indices;
  final int bestScore;
}

_HintResult _findHintIndices(_HintPayload payload) {
  const gridSize = 4;

  _HintResult bestCandidate = const _HintResult(indices: <int>[], bestScore: 0);

  _HintResult _evaluateLine(
      List<String> lineLetters,
      List<int> lineIndices,
      ) {
    int bestScore = 0;
    List<int> bestIndices = const <int>[];

    for (final word in payload.dictionary) {
      if (word.isEmpty || word.length > lineLetters.length) continue;

      int score = 0;
      for (int i = 0; i < word.length; i++) {
        final letter = lineLetters[i];
        if (letter.trim().isEmpty || word[i] != letter) {
          break;
        }
        score++;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIndices = lineIndices.take(word.length).toList();
      }
    }

    return _HintResult(
      indices: bestIndices,
      bestScore: bestScore,
    );
  }

  for (int row = 0; row < gridSize; row++) {
    final indices = <int>[];
    final letters = <String>[];
    for (int col = 0; col < gridSize; col++) {
      final idx = row * gridSize + col;
      indices.add(idx);
      letters.add(payload.letters[idx]);
    }
    final candidate = _evaluateLine(letters, indices);
    if (candidate.bestScore > bestCandidate.bestScore) {
      bestCandidate = candidate;
    }
  }

  for (int col = 0; col < gridSize; col++) {
    final indices = <int>[];
    final letters = <String>[];
    for (int row = 0; row < gridSize; row++) {
      final idx = row * gridSize + col;
      indices.add(idx);
      letters.add(payload.letters[idx]);
    }
    final candidate = _evaluateLine(letters, indices);
    if (candidate.bestScore > bestCandidate.bestScore) {
      bestCandidate = candidate;
    }
  }

  if (bestCandidate.bestScore <= 0) {
    return const _HintResult(indices: <int>[], bestScore: 0);
  }

  return bestCandidate;
}