import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/logo.dart';
import '../application/auth_controller.dart';

/// Shown while the saved session is checked, or if that check failed.
///
/// While loading it looks like the native splash screen (same logo, size and
/// position), so the hand-over to Flutter is invisible.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: auth is AuthRestoreFailed
          ? _RestoreFailed(error: auth.error)
          : const Stack(
              children: [
                Center(
                  child: FanikishaMark(
                    height: FanikishaMark.splashHeight,
                    semanticLabel: 'Fanikisha',
                  ),
                ),
                Align(
                  alignment: Alignment(0, 0.6),
                  child: CircularProgressIndicator(),
                ),
                Align(alignment: Alignment(0, 0.75), child: _SlowStartHint()),
              ],
            ),
    );
  }
}

/// After a few seconds of loading, explains the wait: a server that has been
/// idle can take up to a minute to wake.
class _SlowStartHint extends StatefulWidget {
  const _SlowStartHint();

  static const delay = Duration(seconds: 5);

  @override
  State<_SlowStartHint> createState() => _SlowStartHintState();
}

class _SlowStartHintState extends State<_SlowStartHint> {
  late final Timer _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_SlowStartHint.delay, () => setState(() => _shown = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    // Absent (not just invisible) until due, so screen readers don't
    // announce it on a fast start.
    child: _shown
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.l10n.splashSlowStart,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : const SizedBox.shrink(),
  );
}

class _RestoreFailed extends ConsumerWidget {
  const _RestoreFailed({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(authControllerProvider.notifier);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FanikishaMark(height: 96),
              const SizedBox(height: 32),
              Text(
                l10n.splashRestoreFailed,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(describeError(error, l10n), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: controller.restore,
                child: Text(l10n.actionRetry),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.logout,
                child: Text(l10n.actionLogOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
