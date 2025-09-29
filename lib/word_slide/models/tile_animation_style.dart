import 'package:flutter/material.dart';

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