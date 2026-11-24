import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../application/savings_providers.dart';
import '../data/savings_models.dart';

/// Sets "save N% of each day's sales (or profit)".
class SavingRuleScreen extends ConsumerWidget {
  const SavingRuleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySavingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ruleTitle)),
      body: today.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(todaySavingsProvider),
        ),
        data: (today) => _RuleForm(existing: today.rule),
      ),
    );
  }
}

class _RuleForm extends ConsumerStatefulWidget {
  const _RuleForm({this.existing});

  final SavingRule? existing;

  @override
  ConsumerState<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends ConsumerState<_RuleForm> {
  static const _presets = [5, 10, 15, 20];
  static const _exampleSales = 100000;
  static const _exampleExpenses = 60000;

  final _formKey = GlobalKey<FormState>();
  late SavingBasis _basis = widget.existing?.basis ?? SavingBasis.sales;
  late final _percent = TextEditingController(
    text: '${widget.existing?.percent ?? 10}',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  int? get _percentValue {
    final value = int.tryParse(_percent.text);
    return value != null && value >= 1 && value <= 100 ? value : null;
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(todaySavingsProvider);
      if (!mounted) return;
      showMessage(context, done);
      context.pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error, l10n);
        });
      }
    }
  }

  void _save() {
    if (_busy || !_formKey.currentState!.validate()) return;
    final repository = ref.read(savingsRepositoryProvider);
    _run(
      () => repository.setRule(_basis, _percentValue!),
      context.l10n.ruleSaved,
    );
  }

  void _remove() {
    if (_busy) return;
    final repository = ref.read(savingsRepositoryProvider);
    _run(repository.removeRule, context.l10n.ruleRemove);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final percent = _percentValue;
    final example = percent == null
        ? null
        : SavingRule(
            basis: _basis,
            percent: percent,
          ).targetFor(sales: _exampleSales, expenses: _exampleExpenses);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.ruleBasisLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<SavingBasis>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: SavingBasis.sales,
                label: Text(l10n.businessSales),
              ),
              ButtonSegment(
                value: SavingBasis.profit,
                label: Text(l10n.businessProfit),
              ),
            ],
            selected: {_basis},
            onSelectionChanged: (s) => setState(() => _basis = s.first),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _percent,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => setState(() {}),
            validator: (_) =>
                _percentValue == null ? l10n.rulePercentInvalid : null,
            decoration: InputDecoration(
              labelText: l10n.rulePercentLabel,
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text('$p%'),
                  selected: percent == p,
                  onSelected: (_) => setState(() => _percent.text = '$p'),
                ),
            ],
          ),
          if (example != null) ...[
            const SizedBox(height: 16),
            Text(
              _basis == SavingBasis.sales
                  ? l10n.ruleExampleSales(
                      formatTzs(_exampleSales),
                      formatTzs(example),
                    )
                  : l10n.ruleExampleProfit(
                      formatTzs(_exampleSales - _exampleExpenses),
                      formatTzs(example),
                    ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FormError(_error),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const ButtonSpinner() : Text(l10n.ruleSave),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              child: Text(l10n.ruleRemove),
            ),
          ],
        ],
      ),
    );
  }
}
