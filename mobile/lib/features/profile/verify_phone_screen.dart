import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/button_spinner.dart';
import '../../core/widgets/form_error.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/auth_repository.dart';
import '../auth/data/user.dart';

/// Texts a code to the user's phone and checks it.
class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  final _code = TextEditingController();
  PhoneCodeSent? _sent;
  bool _sending = false;
  bool _confirming = false;
  String? _error;
  Timer? _ticker;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    // Send the first code straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _send() async {
    if (_sending) return;
    final l10n = context.l10n;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await _repository.sendPhoneCode(language: l10n.localeName);
      if (!mounted) return;
      setState(() => _sent = sent);
      _startCountdown(sent.resendAvailableAt.difference(DateTime.now()));
    } on ApiException catch (error) {
      if (!mounted) return;
      switch (error.errorCode) {
        case 'already_verified':
          await _finish(await _repository.currentUser());
          return;
        case 'resend_too_soon':
          final wait = (error.details['retryAfterSeconds'] as num?)?.toInt();
          if (wait != null) _startCountdown(Duration(seconds: wait));
      }
      setState(() => _error = describePhoneError(error, l10n));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text;
    if (_confirming || code.length != 6) return;
    final l10n = context.l10n;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await _finish(await _repository.confirmPhoneCode(code));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describePhoneError(error, l10n);
        _code.clear();
      });
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _finish(User user) async {
    ref.read(authControllerProvider.notifier).updateUser(user);
    if (!mounted) return;
    showMessage(context, context.l10n.verifyPhoneDone);
    context.pop();
  }

  void _startCountdown(Duration wait) {
    _ticker?.cancel();
    setState(
      () => _resendIn = wait.inMilliseconds <= 0
          ? 0
          : (wait.inMilliseconds / 1000).ceil(),
    );
    if (_resendIn == 0) return;
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
    final auth = ref.watch(authControllerProvider);
    final phone =
        _sent?.phone ?? (auth is SignedIn ? auth.user.phone : null) ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyPhoneTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.sms_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            _sent == null
                ? l10n.verifyPhoneSending(phone)
                : l10n.verifyPhoneSentTo(phone),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            enabled: _sent != null && !_confirming,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 12),
            onChanged: (value) {
              if (value.length == 6) _confirm();
            },
            decoration: InputDecoration(
              labelText: l10n.verifyPhoneCodeLabel,
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          FormError(_error),
          FilledButton(
            onPressed: _sent == null || _confirming ? null : _confirm,
            child: _confirming
                ? const ButtonSpinner()
                : Text(l10n.verifyPhoneSubmit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending || _resendIn > 0 ? null : _send,
            child: Text(
              _resendIn > 0
                  ? l10n.verifyPhoneResendIn(_resendIn)
                  : l10n.verifyPhoneResend,
            ),
          ),
        ],
      ),
    );
  }
}

/// A verification error in the app's language.
String describePhoneError(ApiException error, AppLocalizations l10n) =>
    switch (error.errorCode) {
      'no_phone' => l10n.phoneErrorNoPhone,
      'resend_too_soon' => l10n.phoneErrorResendTooSoon(
        (error.details['retryAfterSeconds'] as num?)?.toInt() ?? 60,
      ),
      'daily_limit' => l10n.phoneErrorDailyLimit,
      'sms_failed' => l10n.phoneErrorSmsFailed,
      'code_expired' => l10n.phoneErrorCodeExpired,
      'code_incorrect' => l10n.phoneErrorCodeIncorrect(
        (error.details['triesLeft'] as num?)?.toInt() ?? 1,
      ),
      'too_many_attempts' => l10n.phoneErrorTooManyAttempts,
      _ => describeError(error, l10n),
    };
