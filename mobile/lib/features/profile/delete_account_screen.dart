import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/validators.dart';
import '../../core/widgets/button_spinner.dart';
import '../../core/widgets/form_error.dart';
import '../../core/widgets/password_field.dart';
import '../auth/application/auth_controller.dart';

/// Permanently deletes the account after the password is entered.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    // Captured now: once signed out, this screen is gone.
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(password: _password.text);
      // Signed out: the router returns to the welcome screen.
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
    } catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = describeError(error, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccount)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteAccountBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            PasswordField(
              controller: _password,
              label: l10n.deleteAccountPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              validator: (v) => validateRequired(v, l10n),
            ),
            const SizedBox(height: 24),
            FormError(_error),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: _deleting ? null : _delete,
              child: _deleting
                  ? const ButtonSpinner()
                  : Text(l10n.deleteAccountSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
