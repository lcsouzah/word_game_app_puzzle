/// Defines the type of visual highlight currently applied to a tile.
enum TileHighlightKind {
  /// No highlight is active for the tile.
  none,

  /// The tile is highlighted because it is part of a hint.
  hint,

  /// The tile is highlighted because it belongs to a solved word animation.
  solved,
}