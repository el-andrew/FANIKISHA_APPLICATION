import 'package:flutter/material.dart';

/// The Fanikisha logo (mark and wordmark), in a light colour on dark themes.
class FanikishaLogo extends StatelessWidget {
  const FanikishaLogo({super.key, this.width = 160});

  /// The width the native splash screen uses, so the in-app splash that
  /// follows it looks identical.
  static const splashWidth = 154.0;

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
      width: width,
      semanticLabel: 'Fanikisha',
    );
  }
}
