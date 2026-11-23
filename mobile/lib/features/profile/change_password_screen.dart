import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/validators.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/button_spinner.dart';
import '../../core/widgets/form_error.dart';
import '../../core/widgets/password_field.dart';
import '../auth/application/auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider);
    if (auth is! SignedIn) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            email: auth.user.email,
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (!mounted) return;
      showMessage(context, l10n.changePasswordDone);
      context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileChangePassword)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PasswordField(
              controller: _current,
              label: l10n.changePasswordCurrent,
              validator: (v) => validateRequired(v, l10n),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _new,
              label: l10n.changePasswordNew,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => validateNewPassword(v, l10n),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirm,
              label: l10n.confirmPasswordLabel,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != _new.text ? l10n.passwordsDoNotMatch : null,
            ),
            const SizedBox(height: 32),
            FormError(_error),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const ButtonSpinner()
                  : Text(l10n.changePasswordSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
