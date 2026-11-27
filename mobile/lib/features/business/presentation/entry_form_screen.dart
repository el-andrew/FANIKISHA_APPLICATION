import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../application/business_providers.dart';
import '../data/business_models.dart';

/// Records a sale or expense, or edits one when [entryId] is given.
class EntryFormScreen extends ConsumerWidget {
  const EntryFormScreen({super.key, this.entryId, this.initialType});

  final String? entryId;

  /// What a new entry starts as: the Sale and Expense buttons choose it.
  final EntryType? initialType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = entryId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.entryNewTitle)),
        body: _EntryForm(initialType: initialType),
      );
    }
    final entry = ref.watch(entryProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entryEditTitle),
        actions: [
          if (entry.hasValue)
            IconButton(
              tooltip: l10n.entryDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, id),
            ),
        ],
      ),
      body: entry.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(entryProvider(id)),
        ),
        data: (entry) => _EntryForm(existing: entry),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.entryDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.entryDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(businessRepositoryProvider).delete(id);
      refreshBusinessData(ref);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) showMessage(context, describeError(error, l10n));
    }
  }
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.existing, this.initialType});

  final BusinessEntry? existing;
  final EntryType? initialType;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  late EntryType _type =
      widget.existing?.type ?? widget.initialType ?? EntryType.sale;
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? null
        : formatGrouped(widget.existing!.amount),
  );
  late final _category = TextEditingController(text: widget.existing?.category);
  late final _note = TextEditingController(text: widget.existing?.note);
  late DateTime _date =
      widget.existing?.occurredOn ?? DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  String? _error;

  /// One key per distinct entry, reused when retrying the same one.
  ({String key, String fingerprint})? _attempt;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final repository = ref.read(businessRepositoryProvider);
    final amount = parseAmount(_amount.text)!;
    final category = trimmedOrNull(_category.text);
    final note = trimmedOrNull(_note.text);
    final existing = widget.existing;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (existing == null) {
        final fingerprint = '${_type.name}|$amount|${toDateOnly(_date)}';
        final attempt = _attempt;
        final key = attempt != null && attempt.fingerprint == fingerprint
            ? attempt.key
            : const Uuid().v4();
        _attempt = (key: key, fingerprint: fingerprint);
        await repository.create(
          type: _type,
          amount: amount,
          occurredOn: _date,
          category: category,
          note: note,
          idempotencyKey: key,
        );
      } else {
        await repository.update(
          existing.id,
          type: _type,
          amount: amount,
          occurredOn: _date,
          category: category,
          note: note,
        );
      }
      refreshBusinessData(ref);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = describeError(error, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final expenseCategories = [
      l10n.categoryStock,
      l10n.categoryRent,
      l10n.categoryTransport,
      l10n.categoryWages,
      l10n.categoryUtilities,
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<EntryType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: EntryType.sale,
                icon: const Icon(Icons.south_west),
                label: Text(l10n.entrySale),
              ),
              ButtonSegment(
                value: EntryType.expense,
                icon: const Icon(Icons.north_east),
                label: Text(l10n.entryExpense),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amount,
            autofocus: widget.existing == null,
            keyboardType: TextInputType.number,
            inputFormatters: [AmountInputFormatter()],
            validator: (v) => validateAmount(v, l10n),
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              labelText: l10n.entryAmount,
              prefixText: 'TZS ',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _category,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 40,
            decoration: InputDecoration(labelText: l10n.entryCategory),
          ),
          if (_type == EntryType.expense)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in expenseCategories)
                  ActionChip(
                    label: Text(c),
                    onPressed: () => setState(() => _category.text = c),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.entryNote),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l10n.entryDate),
            trailing: Text(
              formatDate(_date, context.localeName),
              style: theme.textTheme.titleSmall,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 24),
          FormError(_error),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const ButtonSpinner() : Text(l10n.entrySave),
          ),
        ],
      ),
    );
  }
}
