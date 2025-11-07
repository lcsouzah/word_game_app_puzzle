import 'package:flutter/material.dart';

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