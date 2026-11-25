import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../../../core/widgets/password_field.dart';
import '../application/auth_controller.dart';

/// Resets a forgotten password with a code texted to the account's verified
/// phone: first the email, then the code and a new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _resendWait = Duration(seconds: 60);

  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// The email a code was requested for; null while asking for it.
  String? _sentTo;
  bool _busy = false;
  String? _error;
  Timer? _ticker;
  int _resendIn = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_busy) return;
    // A resend reuses the email the first code was sent for; the email form
    // is no longer on screen then.
    final resend = _sentTo;
    if (resend == null && !_emailForm.currentState!.validate()) return;
    final l10n = context.l10n;
    final email = resend ?? _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: email, language: l10n.localeName);
      if (!mounted) return;
      setState(() => _sentTo = email);
      _startCountdown();
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy || !_resetForm.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            email: _sentTo!,
            code: _code.text,
            newPassword: _password.text,
          );
      // Signed in: the router moves to the dashboard.
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = describeCodeError(error, l10n));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _resendIn = _resendWait.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final sentTo = _sentTo;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.forgotPasswordTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (sentTo == null)
              Form(
                key: _emailForm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.forgotPasswordIntro, style: muted),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _requestCode(),
                      validator: (v) => validateEmail(v, l10n),
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FormError(_error),
                    FilledButton(
                      onPressed: _busy ? null : _requestCode,
                      child: _busy
                          ? const ButtonSpinner()
                          : Text(l10n.forgotPasswordSend),
                    ),
                  ],
                ),
              )
            else
              Form(
                key: _resetForm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.forgotPasswordSent(sentTo)),
                    const SizedBox(height: 8),
                    Text(l10n.forgotPasswordNoPhone, style: muted),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      validator: (v) =>
                          (v ?? '').length == 6 ? null : l10n.fieldRequired,
                      decoration: InputDecoration(
                        labelText: l10n.verifyPhoneCodeLabel,
                        prefixIcon: const Icon(Icons.sms_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _password,
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
                      onSubmitted: (_) => _reset(),
                      validator: (v) =>
                          v != _password.text ? l10n.passwordsDoNotMatch : null,
                    ),
                    const SizedBox(height: 24),
                    FormError(_error),
                    FilledButton(
                      onPressed: _busy ? null : _reset,
                      child: _busy
                          ? const ButtonSpinner()
                          : Text(l10n.forgotPasswordSubmit),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy || _resendIn > 0 ? null : _requestCode,
                      child: Text(
                        _resendIn > 0
                            ? l10n.verifyPhoneResendIn(_resendIn)
                            : l10n.verifyPhoneResend,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _sentTo = null;
                              _error = null;
                              _code.clear();
                            }),
                      child: Text(l10n.forgotPasswordOtherEmail),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
