import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/logo.dart';
import '../application/auth_controller.dart';

/// Shown while the saved session is checked, or if that check failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FanikishaLogo(),
                const SizedBox(height: 32),
                if (auth is AuthRestoreFailed) ...[
                  Text(
                    l10n.splashRestoreFailed,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    describeError(auth.error, l10n),
                    textAlign: TextAlign.center,
                  ),
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
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
