import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/legal_links.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../../../core/widgets/password_field.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _businessName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _businessName,
      _email,
      _phone,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phone: trimmedOrNull(_phone.text),
            businessName: trimmedOrNull(_businessName.text),
          );
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
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.registerTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) => validateFullName(v, l10n),
                  decoration: InputDecoration(
                    labelText: l10n.fullNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.organizationName],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.businessNameLabel,
                    prefixIcon: const Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) => validateEmail(v, l10n),
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  validator: (v) => validateOptionalPhone(v, l10n),
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    helperText: l10n.phoneHelper,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
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
                      v != _password.text ? l10n.passwordsDoNotMatch : null,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.legalAgreement,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () =>
                          openLegalPage(context, ref, LegalPage.terms),
                      child: Text(l10n.legalTerms),
                    ),
                    TextButton(
                      onPressed: () =>
                          openLegalPage(context, ref, LegalPage.privacy),
                      child: Text(l10n.legalPrivacy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FormError(_error),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const ButtonSpinner()
                      : Text(l10n.registerButton),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.registerHaveAccount),
                    TextButton(
                      onPressed: () => context.pushReplacement('/login'),
                      child: Text(l10n.registerLogIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
