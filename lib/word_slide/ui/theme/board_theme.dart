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

/// Input parameters supplied to a border style when building decorations.
class TileBorderStyleContext {
  final Color tileColor;
  final Color borderColor;
  final bool highlighted;

  const TileBorderStyleContext({
    required this.tileColor,
    required this.borderColor,
    required this.highlighted,
  });
}

/// Visual fragments describing how a tile border should appear.
class TileBorderDecoration {
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final List<BoxShadow> boxShadows;
  final Color? fillColor;
  final Decoration? foregroundDecoration;

  const TileBorderDecoration({
    this.borderRadius,
    this.border,
    this.gradient,
    this.boxShadows = const [],
    this.fillColor,
    this.foregroundDecoration,
  });
}

/// A configurable preset for styling puzzle tile borders.
class TileBorderStyle {
  final String id;
  final String displayName;
  final bool isPremium;
  final TileBorderDecoration Function(TileBorderStyleContext context) _builder;

  const TileBorderStyle({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required TileBorderDecoration Function(TileBorderStyleContext context)
    decorationBuilder,
  }) : _builder = decorationBuilder;

  TileBorderDecoration buildDecoration({
    required Color tileColor,
    required Color borderColor,
    required bool highlighted,
  }) =>
      _builder(
        TileBorderStyleContext(
          tileColor: tileColor,
          borderColor: borderColor,
          highlighted: highlighted,
        ),
      );
}

/// Registry of built-in tile border styles.
class TileBorderStyles {
  static final TileBorderStyle _none = TileBorderStyle(
    id: 'none',
    displayName: 'None',
    isPremium: false,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(8),
      boxShadows: const [],
    ),
  );
  static final TileBorderStyle classicOutline = TileBorderStyle(
    id: 'classic_outline',
    displayName: 'Classic Outline',
    isPremium: false,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.white,
        width: 2,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    ),
  );

  static final TileBorderStyle roundedGlow = TileBorderStyle(
    id: 'rounded_glow',
    displayName: 'Rounded Glow',
    isPremium: false,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: context.borderColor.withOpacity(0.5),
        width: 2,
      ),
      boxShadows: [
        BoxShadow(
          color: context.borderColor.withOpacity(0.4),
          blurRadius: 18,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
  );

  static final TileBorderStyle insetShadow = TileBorderStyle(
    id: 'inset_shadow',
    displayName: 'Inset Shadow',
    isPremium: false,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.black.withOpacity(0.25),
        width: 1.5,
      ),
      boxShadows: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    ),
  );

  static final TileBorderStyle goldGloss = TileBorderStyle(
    id: 'gold_gloss',
    displayName: 'Gold Gloss',
    isPremium: true,
    decorationBuilder: (context) => const TileBorderDecoration(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      gradient: LinearGradient(
        colors: [
          Color(0xFFFFF3B0),
          Color(0xFFFFD700),
          Color(0xFFF6A623),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFFFE082), width: 2.5),
      ),
      boxShadows: [
        BoxShadow(
          color: Color(0xFFFFD54F),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
  );

  static final TileBorderStyle silverGlow = TileBorderStyle(
    id: 'silver_glow',
    displayName: 'Silver Glow',
    isPremium: true,
    decorationBuilder: (context) => const TileBorderDecoration(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      gradient: LinearGradient(
        colors: [
          Color(0xFFE0E0E0),
          Color(0xFFBDBDBD),
          Color(0xFF9E9E9E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFF5F5F5), width: 2.2),
      ),
      boxShadows: [
        BoxShadow(
          color: Color(0xFFB0BEC5),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
  );

  static final TileBorderStyle bronzeEdge = TileBorderStyle(
    id: 'bronze_edge',
    displayName: 'Bronze Edge',
    isPremium: true,
    decorationBuilder: (context) => const TileBorderDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      gradient: LinearGradient(
        colors: [
          Color(0xFFFFE0B2),
          Color(0xFFB9743A),
          Color(0xFF8D5524),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFFFCC80), width: 2),
      ),
      boxShadows: [
        BoxShadow(
          color: Color(0xFF8D6E63),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
  );

  static final TileBorderStyle neonGlow = TileBorderStyle(
    id: 'neon_glow',
    displayName: 'Neon Glow',
    isPremium: true,
    decorationBuilder: (context) {
      final glowColor = Colors.cyanAccent.withOpacity(context.highlighted ? 0.85 : 0.6);
      final pulseColor = Colors.pinkAccent.withOpacity(context.highlighted ? 0.6 : 0.35);
      return TileBorderDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3A0CA3),
            Color(0xFF4361EE),
            Color(0xFF4CC9F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.black.withOpacity(0.45),
          width: 1.4,
        ),
        boxShadows: [
          BoxShadow(
            color: glowColor,
            blurRadius: 28,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: pulseColor,
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      );
    },
  );

  static final TileBorderStyle frostedGlass = TileBorderStyle(
    id: 'frosted_glass',
    displayName: 'Frosted Glass',
    isPremium: false,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.75),
          Colors.white.withOpacity(0.35),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: Colors.white.withOpacity(context.highlighted ? 0.9 : 0.6),
        width: 1.8,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
      foregroundDecoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(context.highlighted ? 0.35 : 0.15),
            Colors.white.withOpacity(0.0),
          ],
          center: Alignment.topLeft,
          radius: 1.2,
        ),
      ),
      fillColor: context.tileColor.withOpacity(0.3),
    ),
  );

  static final TileBorderStyle lavaEdge = TileBorderStyle(
    id: 'lava_edge',
    displayName: 'Lava Edge',
    isPremium: true,
    decorationBuilder: (context) => TileBorderDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF9E00),
          Color(0xFFFF4D00),
          Color(0xFFB00020),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border.all(
        color: Colors.deepOrangeAccent.withOpacity(context.highlighted ? 0.9 : 0.7),
        width: 2.4,
      ),
      boxShadows: const [
        BoxShadow(
          color: Color(0x66FF6D00),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x33D32F2F),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.35),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  );

  static final Map<String, TileBorderStyle> _stylesById = {
    for (final style in [
      _none,
      classicOutline,
      roundedGlow,
      insetShadow,
      goldGloss,
      silverGlow,
      bronzeEdge,
      neonGlow,
      frostedGlass,
      lavaEdge,
    ])
      style.id: style,
  };

  static TileBorderStyle byId(String id) =>
      _stylesById[id] ?? classicOutline;

  static TileBorderStyle? tryById(String id) => _stylesById[id];

  static Iterable<TileBorderStyle> get all => _stylesById.values;

  static Iterable<TileBorderStyle> get freeStyles =>
      all.where((style) => !style.isPremium);

  static Iterable<TileBorderStyle> get premiumStyles =>
      all.where((style) => style.isPremium);

  static TileBorderStyle get defaultStyle => classicOutline;

  static TileBorderStyle get none => _none;

  static String migrateLegacyAssetPath(String? path) {
    switch (path) {
      case 'assets/borders/border_red.png':
        return roundedGlow.id;
      case 'assets/borders/border_green.png':
        return insetShadow.id;
      case 'assets/borders/border_blue.png':
        return classicOutline.id;
      default:
        return defaultStyle.id;
    }
  }
}

/// Identifies the animation behavior used when tiles swap or idle.
enum TileAnimationBehavior {
  /// Traditional slide animation that eases tiles into place.
  slide,

  /// A quick fade out/in that makes tiles feel like they teleport.
  teleport,

  /// A subtle opacity pulse that keeps the tile shimmering.
  blink,

  /// A scale and fade combination that makes tiles puff into place.
  puff,
}

/// Describes the animation style applied to puzzle tiles. Styles can be marked
/// as premium so they can be surfaced in the store alongside border styles.
class TileAnimationStyle {
  const TileAnimationStyle({
    required this.id,
    required this.displayName,
    required this.description,
    required this.behavior,
    required this.icon,
    required this.transitionDuration,
    this.switchInCurve = Curves.easeOut,
    this.switchOutCurve = Curves.easeIn,
    this.idleLoopPeriod,
    this.idleOpacityLowerBound,
    this.puffScaleFactor,
    this.isPremium = false,
  });

  /// Unique identifier that is also used as the in-app purchase product ID.
  final String id;

  /// Human friendly name shown in the UI.
  final String displayName;

  /// Short description explaining the animation feel.
  final String description;

  /// The primary animation behavior.
  final TileAnimationBehavior behavior;

  /// Icon used in the settings and store previews.
  final IconData icon;

  /// Duration used when tiles swap or update.
  final Duration transitionDuration;

  /// Curve applied to the switch-in animation.
  final Curve switchInCurve;

  /// Curve applied to the switch-out animation.
  final Curve switchOutCurve;

  /// Period for looping idle animations (used by [TileAnimationBehavior.blink]).
  final Duration? idleLoopPeriod;

  /// Minimum opacity reached during idle animation pulses.
  final double? idleOpacityLowerBound;

  /// Scale factor used by puff style transitions.
  final double? puffScaleFactor;

  /// Whether this style requires a premium purchase.
  final bool isPremium;
}

/// Catalog of the available tile animation styles.
class TileAnimationStyles {
  static const TileAnimationStyle slide = TileAnimationStyle(
    id: 'anim_slide',
    displayName: 'Slide',
    description: 'Smoothly glides tiles into position.',
    behavior: TileAnimationBehavior.slide,
    icon: Icons.swipe,
    transitionDuration: Duration(milliseconds: 220),
    switchInCurve: Curves.easeOutQuad,
    switchOutCurve: Curves.easeInQuad,
  );

  static const TileAnimationStyle teleport = TileAnimationStyle(
    id: 'anim_teleport',
    displayName: 'Teleport',
    description: 'Tiles fade out and blink back instantly.',
    behavior: TileAnimationBehavior.teleport,
    icon: Icons.auto_awesome_motion,
    transitionDuration: Duration(milliseconds: 140),
    switchInCurve: Curves.easeIn,
    switchOutCurve: Curves.easeOut,
    isPremium: true,
  );

  static const TileAnimationStyle blink = TileAnimationStyle(
    id: 'anim_blink',
    displayName: 'Blink',
    description: 'A gentle shimmering opacity pulse.',
    behavior: TileAnimationBehavior.blink,
    icon: Icons.brightness_low,
    transitionDuration: Duration(milliseconds: 180),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    idleLoopPeriod: Duration(milliseconds: 1500),
    idleOpacityLowerBound: 0.45,
  );

  static const TileAnimationStyle puff = TileAnimationStyle(
    id: 'anim_puff',
    displayName: 'Puff',
    description: 'Scale and fade tiles like a magic poof.',
    behavior: TileAnimationBehavior.puff,
    icon: Icons.local_fire_department,
    transitionDuration: Duration(milliseconds: 260),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeInBack,
    puffScaleFactor: 1.1,
    isPremium: true,
  );

  /// Styles ordered for display.
  static const List<TileAnimationStyle> all = <TileAnimationStyle>[
    slide,
    blink,
    teleport,
    puff,
  ];

  static TileAnimationStyle get defaultStyle => slide;

  static TileAnimationStyle byId(String id) {
    return tryById(id) ?? defaultStyle;
  }

  static TileAnimationStyle? tryById(String? id) {
    if (id == null) {
      return null;
    }
    for (final style in all) {
      if (style.id == id) {
        return style;
      }
    }
    return null;
  }

  static Iterable<TileAnimationStyle> get freeStyles =>
      all.where((style) => !style.isPremium);

  static Iterable<TileAnimationStyle> get premiumStyles =>
      all.where((style) => style.isPremium);
}
/// Defines the type of visual highlight currently applied to a tile.
enum TileHighlightKind {
  /// No highlight is active for the tile.
  none,

  /// The tile is highlighted because it is part of a hint.
  hint,

  /// The tile is highlighted because it belongs to a solved word animation.
  solved,
}