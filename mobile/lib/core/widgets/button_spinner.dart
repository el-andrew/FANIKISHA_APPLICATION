import 'package:flutter/material.dart';

/// A small spinner that fits inside a button while it submits.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(strokeWidth: 2.5),
  );
}
