import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/legal_links.dart';
import '../../core/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ui.dart';
import '../auth/application/auth_controller.dart';
import '../reminders/reminder_widgets.dart';

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
    const gap = SizedBox(height: AppSpace.m);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          AppSpace.xs,
          AppSpace.l,
          AppSpace.xl,
        ),
        children: [
          AppCard(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: AppSize.touch / 2,
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    child: Text(
                      user.firstName.characters.first.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: theme.textTheme.titleMedium),
                      if (user.businessName != null)
                        Text(
                          user.businessName!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      Text(
                        [user.email, ?user.phone].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (user.phoneVerified)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s),
                          child: StatusBadge(
                            label: l10n.phoneVerified,
                            tone: StatusTone.positive,
                            icon: Icons.verified_outlined,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          gap,
          _Group(
            children: [
              if (user.needsPhoneVerification)
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: Text(l10n.verifyPhoneTitle),
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
            ],
          ),
          gap,
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.profileLanguage),
                trailing: Text(
                  _languageName(locale, l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                onTap: () => _chooseLanguage(context, ref, locale),
              ),
              const ReminderSettingsTiles(),
            ],
          ),
          gap,
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.legalPrivacy),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: () => openLegalPage(context, ref, LegalPage.privacy),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.legalTerms),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: () => openLegalPage(context, ref, LegalPage.terms),
              ),
            ],
          ),
          gap,
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.actionLogOut),
                onTap: () => _logOut(context, ref),
              ),
              ListTile(
                iconColor: AppColors.attention,
                textColor: AppColors.attention,
                leading: const Icon(Icons.delete_forever_outlined),
                title: Text(l10n.deleteAccount),
                onTap: () => context.push('/profile/delete'),
              ),
            ],
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

/// Settings rows in one white card, divided by thin lines.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.card),
    child: Material(
      color: AppColors.card,
      child: ListTileTheme(
        data: ListTileThemeData(
          iconColor: AppColors.muted,
          titleTextStyle: Theme.of(context).textTheme.titleSmall,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
        ),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const Divider(indent: AppSpace.l + 40),
              child,
            ],
          ],
        ),
      ),
    ),
  );
}
