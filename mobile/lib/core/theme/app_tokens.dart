/// Fanikisha's proportions: one spacing grid, one set of corner radii and
/// fixed sizes for repeated shapes, so every screen shares the same rhythm.
library;

/// Spacing on an 8-point grid (with 4 and 12 for tight spots).
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;

  /// Page margins, card padding, gaps between cards.
  static const double l = 16;

  /// Gaps between sections.
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  /// Cards and sheets.
  static const double card = 16;

  /// Buttons, fields, segmented controls.
  static const double control = 12;

  /// Pills: badges and chips.
  static const double pill = 999;
}

abstract final class AppSize {
  /// Home's round action buttons, and their icon.
  static const double action = 56;
  static const double actionIcon = 24;

  /// The round icon at the start of a list row, and its icon.
  static const double rowIcon = 40;
  static const double rowIconGlyph = 20;

  /// Progress rings next to goals.
  static const double ring = 44;

  /// Main buttons, and the smaller ones inside cards.
  static const double button = 52;
  static const double buttonCompact = 40;

  /// Material's minimum touch target.
  static const double touch = 48;
}
