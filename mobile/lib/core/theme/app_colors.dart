import 'package:flutter/painting.dart';

/// Fanikisha's palette: greens and neutrals only.
///
/// Text colours meet WCAG AA (4.5:1) on [ground] and [card]. Positive and
/// attention states differ in lightness and come with an icon or a sign,
/// never colour alone.
abstract final class AppColors {
  /// The main action colour, the Home header, active tabs.
  static const deepGreen = Color(0xFF215732);

  /// Brand green: progress fills and the avatar. Not for text.
  static const brandGreen = Color(0xFF43AF2A);

  /// Page background.
  static const ground = Color(0xFFF4F7F3);
  static const card = Color(0xFFFFFFFF);

  /// Main text.
  static const ink = Color(0xFF17251B);

  /// Secondary text: labels, dates.
  static const muted = Color(0xFF4A5A4E);

  /// Light lines between rows, and empty progress tracks.
  static const line = Color(0xFFE6EBE4);

  /// Borders of outlined buttons and fields.
  static const border = Color(0xFFD5DED3);

  /// Behind round icons and the active tab.
  static const tint = Color(0xFFE5F2E1);

  /// On track, money in.
  static const positiveBg = Color(0xFFE3F2DF);
  static const positive = Color(0xFF1E5A2E);

  /// Amounts added (+).
  static const moneyIn = Color(0xFF1F6E33);

  /// Behind, money out: an olive green.
  static const attentionBg = Color(0xFFEEF5D6);
  static const attention = Color(0xFF4D5F0F);

  /// On the deep-green header.
  static const onHeader = Color(0xFFFFFFFF);
  static const onHeaderMuted = Color(0xFFCFE3D2);
}
