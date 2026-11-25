import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../../savings/application/savings_providers.dart';
import '../application/goals_providers.dart';
import '../data/goal.dart';

/// Creates a goal, or edits one when [goalId] is given.
class GoalFormScreen extends ConsumerWidget {
  const GoalFormScreen({super.key, this.goalId});

  final String? goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = goalId;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          id == null ? l10n.goalFormNewTitle : l10n.goalFormEditTitle,
        ),
      ),
      body: id == null
          ? const _GoalForm()
          : ref
                .watch(goalProvider(id))
                .when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(goalProvider(id)),
                  ),
                  data: (goal) => _GoalForm(existing: goal),
                ),
    );
  }
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _category = TextEditingController(text: widget.existing?.category);
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? null
        : formatGrouped(widget.existing!.targetAmount),
  );
  late final _dateText = TextEditingController();
  late int _priority = widget.existing?.priority ?? 3;
  late DateTime? _targetDate = widget.existing?.targetDate;
  bool _submitting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final date = _targetDate;
    _dateText.text = date == null ? '' : formatDate(date, context.localeName);
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _amount.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? today.add(const Duration(days: 90)),
      firstDate:
          widget.existing?.startDate.add(const Duration(days: 1)) ?? tomorrow,
      lastDate: DateTime(today.year + 20),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _targetDate = picked;
      _dateText.text = formatDate(picked, context.localeName);
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final repository = ref.read(goalsRepositoryProvider);
    final existing = widget.existing;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      final amount = parseAmount(_amount.text)!;
      final category = trimmedOrNull(_category.text);
      final Goal saved;
      if (existing == null) {
        saved = await repository.create(
          name: name,
          targetAmount: amount,
          priority: _priority,
          targetDate: _targetDate!,
          category: category,
        );
      } else {
        saved = await repository.update(
          existing.id,
          name: name,
          targetAmount: amount,
          priority: _priority,
          targetDate: _targetDate!,
          category: category,
        );
      }
      refreshSavingsData(ref);
      if (!mounted) return;
      if (existing == null) {
        context.pushReplacement('/goals/${saved.id}');
      } else {
        context.pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 80,
            validator: (v) => validateRequired(v, l10n),
            decoration: InputDecoration(
              labelText: l10n.goalNameLabel,
              hintText: l10n.goalNameHint,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [AmountInputFormatter()],
            validator: (v) => validateAmount(v, l10n),
            decoration: InputDecoration(
              labelText: l10n.goalTargetAmountLabel,
              prefixText: 'TZS ',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateText,
            readOnly: true,
            onTap: _pickDate,
            validator: (_) =>
                _targetDate == null ? l10n.goalTargetDateMissing : null,
            decoration: InputDecoration(
              labelText: l10n.goalTargetDateLabel,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _category,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: l10n.goalCategoryLabel,
              hintText: l10n.goalCategoryHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.goalPriorityLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            l10n.goalPriorityHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var p = 1; p <= 5; p++)
                ChoiceChip(
                  label: Text(priorityLabel(p, l10n)),
                  selected: _priority == p,
                  onSelected: (_) => setState(() => _priority = p),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FormError(_error),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const ButtonSpinner()
                : Text(
                    widget.existing == null
                        ? l10n.goalFormCreate
                        : l10n.goalFormSave,
                  ),
          ),
        ],
      ),
    );
  }
}
