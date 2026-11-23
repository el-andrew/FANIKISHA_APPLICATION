import 'package:flutter/material.dart';

/// The Fanikisha logo on a light tile, so it stays visible in dark mode.
class FanikishaLogo extends StatelessWidget {
  const FanikishaLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 5),
      child: ColoredBox(
        color: Colors.white,
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          semanticLabel: 'Fanikisha',
        ),
      ),
    );
  }
}
