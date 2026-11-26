import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../application/savings_providers.dart';
import '../data/savings_models.dart';
import 'split_list.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key, this.initialAmount});

  /// Pre-fills the amount, e.g. the rest of today's saving target.
  final int? initialAmount;

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    if (initial != null && initial > 0) {
      _amount.text = formatGrouped(initial);
      // Show the split for it straight away.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onAmountChanged(_amount.text),
      );
    }
  }

  Timer? _debounce;
  int _previewRequest = 0;
  DepositSplit? _preview;
  bool _previewLoading = false;
  bool _submitting = false;
  String? _error;

  /// One key per distinct deposit: a retry of the same amount and note reuses
  /// it, so the server records the deposit once even if a response was lost.
  ({String key, int amount, String? note})? _attempt;

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
    final amount = parseAmount(text);
    if (amount == null || amount <= 0) {
      setState(() {
        _preview = null;
        _previewLoading = false;
      });
      return;
    }
    setState(() => _previewLoading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadPreview(amount),
    );
  }

  Future<void> _loadPreview(int amount) async {
    final request = ++_previewRequest;
    try {
      final preview = await ref.read(savingsRepositoryProvider).preview(amount);
      if (!mounted || request != _previewRequest) return;
      setState(() {
        _preview = preview;
        _previewLoading = false;
      });
    } catch (_) {
      // The preview is a convenience; saving still works without it.
      if (mounted && request == _previewRequest) {
        setState(() {
          _preview = null;
          _previewLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final amount = parseAmount(_amount.text)!;
    final note = trimmedOrNull(_note.text);
    final attempt = _attempt;
    final key =
        attempt != null && attempt.amount == amount && attempt.note == note
        ? attempt.key
        : const Uuid().v4();
    _attempt = (key: key, amount: amount, note: note);

    setState(() {
      _submitting = true;
      _error = null;
    });
    final Deposit deposit;
    try {
      deposit = await ref
          .read(savingsRepositoryProvider)
          .deposit(amount: amount, note: note, idempotencyKey: key);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = describeError(error, l10n);
        });
      }
      return;
    }
    refreshSavingsData(ref);
    if (!mounted) return;
    setState(() => _submitting = false);
    await _showSuccess(deposit);
    if (mounted) context.pop();
  }

  Future<void> _showSuccess(Deposit deposit) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      // It's closed with Done, not by dragging.
      showDragHandle: false,
      builder: (context) => SafeArea(
        // A long split, or a short screen, scrolls instead of overflowing.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.depositSuccessTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.depositSuccessBody(formatTzs(deposit.amount)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SplitList(split: deposit),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amount = parseAmount(_amount.text);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.depositTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [AmountInputFormatter()],
              onChanged: _onAmountChanged,
              validator: (v) => validateAmount(v, l10n),
              style: theme.textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.depositAmountLabel,
                prefixText: 'TZS ',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.depositNoteLabel,
                hintText: l10n.depositNoteHint,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.depositPreviewTitle,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (_previewLoading)
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _previewBody(l10n, theme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FormError(_error),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const ButtonSpinner()
                  : Text(
                      amount != null && amount > 0
                          ? l10n.depositSubmit(formatTzs(amount))
                          : l10n.depositTitle,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewBody(AppLocalizations l10n, ThemeData theme) {
    final preview = _preview;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (preview == null) return Text(l10n.depositPreviewEmpty, style: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview.allocations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l10n.depositPreviewNoGoals, style: muted),
          ),
        SplitList(split: preview),
      ],
    );
  }
}
