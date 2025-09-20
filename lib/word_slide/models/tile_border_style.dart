import 'package:flutter/material.dart';

/// Visual fragments describing how a tile border should appear.
class TileBorderVisuals {
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final List<BoxShadow> boxShadows;
  final Color? fillColor;

  const TileBorderVisuals({
    this.borderRadius,
    this.border,
    this.gradient,
    this.boxShadows = const [],
    this.fillColor,
  });
}

/// A configurable preset for styling puzzle tile borders.
class TileBorderStyle {
  final String id;
  final String displayName;
  final bool isPremium;
  final TileBorderVisuals Function(Color baseColor) _builder;

  const TileBorderStyle({
    required this.id,
    required this.displayName,
    required this.isPremium,
    required TileBorderVisuals Function(Color baseColor) visualsBuilder,
  }) : _builder = visualsBuilder;

  TileBorderVisuals visuals(Color baseColor) => _builder(baseColor);
}

/// Registry of built-in tile border styles.
class TileBorderStyles {
  static final TileBorderStyle classicOutline = TileBorderStyle(
    id: 'classic_outline',
    displayName: 'Classic Outline',
    isPremium: false,
    visualsBuilder: (baseColor) => TileBorderVisuals(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.white.withOpacity(0.6),
        width: 2,
      ),
      boxShadows: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(2, 2),
        ),
      ],
    ),
  );

  static final TileBorderStyle roundedGlow = TileBorderStyle(
    id: 'rounded_glow',
    displayName: 'Rounded Glow',
    isPremium: false,
    visualsBuilder: (baseColor) => TileBorderVisuals(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: baseColor.withOpacity(0.5),
        width: 2,
      ),
      boxShadows: [
        BoxShadow(
          color: baseColor.withOpacity(0.4),
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
    visualsBuilder: (baseColor) => TileBorderVisuals(
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
    visualsBuilder: (_) => const TileBorderVisuals(
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
    visualsBuilder: (_) => const TileBorderVisuals(
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
    visualsBuilder: (_) => const TileBorderVisuals(
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

  static final Map<String, TileBorderStyle> _stylesById = {
    for (final style in [
      classicOutline,
      roundedGlow,
      insetShadow,
      goldGloss,
      silverGlow,
      bronzeEdge,
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