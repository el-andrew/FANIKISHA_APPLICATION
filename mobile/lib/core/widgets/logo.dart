import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Fanikisha mark: the leaf F whose middle bar is a rising arrow.
class FanikishaMark extends StatelessWidget {
  const FanikishaMark({super.key, this.height = 48, this.semanticLabel});

  /// The height the native splash screen draws the mark at (assets/branding
  /// splash images), so the in-app splash that follows it looks identical.
  static const splashHeight = 144.0;

  /// The mark's width over its height.
  static const aspectRatio = 312 / 449;

  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/mark.png',
    height: height,
    width: height * aspectRatio,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );
}

/// "Fanikisha" written with the mark as its F.
class FanikishaWordmark extends StatelessWidget {
  const FanikishaWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final markHeight = fontSize * 1.42;
    return Semantics(
      label: 'Fanikisha',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // The F's foot sits on the text's baseline.
          Baseline(
            baseline: markHeight,
            baselineType: TextBaseline.alphabetic,
            child: FanikishaMark(height: markHeight),
          ),
          SizedBox(width: fontSize * 0.04),
          Text(
            'anikisha',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -fontSize * 0.02,
              color: AppColors.deepGreen,
            ),
          ),
        ],
      ),
    );
  }
}
