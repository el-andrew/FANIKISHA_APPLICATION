import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/validators.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/button_spinner.dart';
import '../../core/widgets/form_error.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/user.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final User _user;
  late final _fullName = TextEditingController(text: _user.fullName);
  late final _businessName = TextEditingController(text: _user.businessName);
  late final _phone = TextEditingController(text: _user.phone);
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = (ref.read(authControllerProvider) as SignedIn).user;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _businessName.dispose();
    _phone.dispose();
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
      final user = await ref
          .read(authRepositoryProvider)
          .updateProfile(
            fullName: _fullName.text.trim(),
            businessName: trimmedOrNull(_businessName.text),
            phone: trimmedOrNull(_phone.text),
          );
      ref.read(authControllerProvider.notifier).updateUser(user);
      if (!mounted) return;
      showMessage(context, l10n.profileUpdated);
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
      appBar: AppBar(title: Text(l10n.profileEdit)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
              validator: (v) => validateFullName(v, l10n),
              decoration: InputDecoration(labelText: l10n.fullNameLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.businessNameLabel),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) => validateOptionalPhone(v, l10n),
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                helperText: l10n.phoneHelper,
              ),
            ),
            const SizedBox(height: 32),
            FormError(_error),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const ButtonSpinner()
                  : Text(l10n.profileSave),
            ),
          ],
        ),
      ),
    );
  }
}
