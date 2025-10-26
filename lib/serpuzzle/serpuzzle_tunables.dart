/// Shared Serpuzzle tuning constants used across gameplay widgets.
/// Keeping them together ensures consistent feel between logic and visuals.
const double snakeTilesPerSecond = 4.0; // difficulty scales this
const int kSubSteps = 16; // 16 micro steps per tile

const Duration kPerTileAnim = Duration(milliseconds: 110); // 100–130ms sweet spot
const double kSegmentOverlap = 0.80; // segmentSpacing = tileSize * 0.80
const double segmentOverlapFactor = 0.80; // expose as named factor for clarity

const Duration impactShakeDuration = Duration(milliseconds: 80);
const double impactShakeAmplitude = 8.0;
const Duration headPulseDuration = Duration(milliseconds: 140);
const Duration damageIndicatorDuration = Duration(milliseconds: 450);
const Duration pointsFloatDuration = Duration(milliseconds: 600);