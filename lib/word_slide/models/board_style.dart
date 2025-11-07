import 'package:flutter/material.dart';

/// Context values supplied to a board style when building decorations.
class BoardStyleContext {
  final ThemeData theme;

  const BoardStyleContext({required this.theme});

  ColorScheme get colorScheme => theme.colorScheme;
}

/// Description of how the puzzle board container should be drawn.
class BoardStyleDecoration {
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final BorderRadius borderRadius;
  final Border? border;
  final List<BoxShadow> boxShadows;
  final EdgeInsetsGeometry padding;
  final DecorationImage? backgroundImage;

  const BoardStyleDecoration({
    this.backgroundColor,
    this.backgroundGradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.border,
    this.boxShadows = const [],
    this.padding = const EdgeInsets.all(16),
    this.backgroundImage,
  });
}

/// A configurable preset for styling the puzzle board container.
class BoardStyle {
  final String id;
  final String displayName;
  final bool isPremium;
  final BoardStyleDecoration Function(BoardStyleContext context) _builder;

  const BoardStyle({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required BoardStyleDecoration Function(BoardStyleContext context)
    decorationBuilder,
  }) : _builder = decorationBuilder;

  BoardStyleDecoration buildDecoration(BoardStyleContext context) =>
      _builder(context);
}

/// Registry of built-in board styles for the puzzle grid container.
class BoardStyles {
  static final BoardStyle classicNeutral = BoardStyle(
    id: 'board_classic_neutral',
    displayName: 'Classic Neutral',
    isPremium: false,
    decorationBuilder: (context) => BoardStyleDecoration(
      backgroundColor: const Color(0xFF211C33),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.14),
        width: 1.4,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 18),
        ),
      ],
      padding: const EdgeInsets.all(16),
    ),
  );
  static final BoardStyle luminousSlate = BoardStyle(
    id: 'board_luminous_slate',
    displayName: 'Luminous Slate',
    isPremium: false,
    decorationBuilder: (context) => BoardStyleDecoration(
      backgroundGradient: const LinearGradient(
        colors: [
          Color(0xFF2F3E5C),
          Color(0xFF1B253A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 2,
      ),
      boxShadows: const [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 28,
          offset: Offset(0, 20),
        ),
      ],
      padding: const EdgeInsets.all(18),
    ),
  );

  static final BoardStyle emeraldBloom = BoardStyle(
    id: 'board_emerald_bloom',
    displayName: 'Emerald Bloom',
    isPremium: false,
    decorationBuilder: (context) => BoardStyleDecoration(
      backgroundGradient: const LinearGradient(
        colors: [
          Color(0xFF2F6F4F),
          Color(0xFF154734),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: Colors.black.withOpacity(0.15),
        width: 1.5,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0xAA1B5E20),
          blurRadius: 30,
          offset: Offset(0, 24),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    ),
  );

  static final BoardStyle auroraVeil = BoardStyle(
    id: 'board_aurora_veil',
    displayName: 'Aurora Veil',
    isPremium: true,
    decorationBuilder: (context) => BoardStyleDecoration(
      backgroundGradient: const SweepGradient(
        colors: [
          Color(0xFF5B86E5),
          Color(0xFF36D1DC),
          Color(0xFF8E54E9),
          Color(0xFF4776E6),
        ],
        startAngle: 0,
        endAngle: 3.14 * 2,
        transform: GradientRotation(0.5),
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withOpacity(0.25),
        width: 2.5,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x6634A0FF),
          blurRadius: 40,
          offset: Offset(0, 26),
        ),
        BoxShadow(
          color: Colors.black54,
          blurRadius: 20,
          offset: Offset(0, 16),
        ),
      ],
      padding: const EdgeInsets.all(24),
    ),
  );

  static final BoardStyle gildedMarble = BoardStyle(
    id: 'board_gilded_marble',
    displayName: 'Gilded Marble',
    isPremium: true,
    decorationBuilder: (context) => BoardStyleDecoration(
      backgroundGradient: const LinearGradient(
        colors: [
          Color(0xFFF5F5F5),
          Color(0xFFE0E0E0),
          Color(0xFFFFFFFF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: const Color(0xFFFDD835),
        width: 2.2,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x66D4AF37),
          blurRadius: 38,
          offset: Offset(0, 28),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    ),
  );

  static final Map<String, BoardStyle> _stylesById = {
    for (final style in [
      classicNeutral,
      luminousSlate,
      emeraldBloom,
      auroraVeil,
      gildedMarble,
    ])
      style.id: style,
  };

  static BoardStyle byId(String id) =>
      _stylesById[id] ?? defaultStyle;

  static BoardStyle? tryById(String id) => _stylesById[id];

  static Iterable<BoardStyle> get all => _stylesById.values;

  static Iterable<BoardStyle> get freeStyles =>
      all.where((style) => !style.isPremium);

  static Iterable<BoardStyle> get premiumStyles =>
      all.where((style) => style.isPremium);

  static BoardStyle get defaultStyle => classicNeutral;
}