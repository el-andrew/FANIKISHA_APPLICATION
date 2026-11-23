import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/locale_controller.dart';
import '../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    if (auth is! SignedIn) return const SizedBox.shrink();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.firstName.characters.first.toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (user.businessName != null)
            Text(
              user.businessName!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          const SizedBox(height: 4),
          Text(
            [user.email, ?user.phone].join(' · '),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (user.phoneVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.phoneVerified,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          if (user.needsPhoneVerification)
            ListTile(
              leading: Icon(
                Icons.sms_outlined,
                color: theme.colorScheme.tertiary,
              ),
              title: Text(l10n.verifyPhoneTitle),
              subtitle: Text(l10n.verifyPhoneBannerBody),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/verify-phone'),
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.profileEdit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profileChangePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/password'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.profileLanguage),
            subtitle: Text(_languageName(locale, l10n)),
            onTap: () => _chooseLanguage(context, ref, locale),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.actionLogOut,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _logOut(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => context.push('/profile/delete'),
          ),
        ],
      ),
    );
  }

  String _languageName(Locale? locale, AppLocalizations l10n) =>
      switch (locale?.languageCode) {
        'en' => l10n.languageEnglish,
        'sw' => l10n.languageSwahili,
        _ => l10n.languageSystem,
      };

  Future<void> _chooseLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale? current,
  ) async {
    final l10n = context.l10n;
    const system = 'system';
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.profileLanguage),
        children: [
          RadioGroup<String>(
            groupValue: current?.languageCode ?? system,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(value: system, title: Text(l10n.languageSystem)),
                RadioListTile(value: 'en', title: Text(l10n.languageEnglish)),
                RadioListTile(value: 'sw', title: Text(l10n.languageSwahili)),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(localeControllerProvider.notifier)
        .set(picked == system ? null : Locale(picked));
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.profileLogOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionLogOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
