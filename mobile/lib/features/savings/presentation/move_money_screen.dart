import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/button_spinner.dart';
import '../../../core/widgets/form_error.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/data/goal.dart';
import '../application/savings_providers.dart';

/// Moves money out of a goal (or general savings when [fromGoalId] is null)
/// into another one, or, with [withdraw], records it as taken out.
class MoveMoneyScreen extends ConsumerWidget {
  const MoveMoneyScreen({super.key, this.fromGoalId, this.withdraw = false});

  final String? fromGoalId;
  final bool withdraw;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = fromGoalId;
    final summary = ref.watch(summaryProvider);
    final source = id == null ? null : ref.watch(goalProvider(id));
    final active = ref.watch(goalsProvider(GoalStatus.active));
    final completed = ref.watch(goalsProvider(GoalStatus.completed));

    Widget body() {
      final loading = [summary, active, completed, ?source];
      final failed = loading.where((v) => v.hasError).firstOrNull;
      if (failed != null) {
        return ErrorView(
          error: failed.error!,
          onRetry: () {
            ref
              ..invalidate(summaryProvider)
              ..invalidate(goalsProvider);
            if (id != null) ref.invalidate(goalProvider(id));
          },
        );
      }
      if (loading.any((v) => !v.hasValue)) return const LoadingView();
      final goal = source?.value;
      return _MoveForm(
        fromGoalId: id,
        fromName: goal?.name ?? l10n.generalSavings,
        available: goal?.savedAmount ?? summary.value!.unallocatedAmount,
        withdraw: withdraw,
        destinations: [
          for (final g in [...active.value!, ...completed.value!])
            if (g.id != id) (id: g.id, name: g.name),
          // General savings, unless the money is already there.
          if (id != null) (id: null, name: l10n.generalSavings),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(withdraw ? l10n.withdrawTitle : l10n.moveMoney),
      ),
      body: body(),
    );
  }
}

typedef _Destination = ({String? id, String name});

class _MoveForm extends ConsumerStatefulWidget {
  const _MoveForm({
    required this.fromGoalId,
    required this.fromName,
    required this.available,
    required this.withdraw,
    required this.destinations,
  });

  final String? fromGoalId;
  final String fromName;
  final int available;
  final bool withdraw;
  final List<_Destination> destinations;

  @override
  ConsumerState<_MoveForm> createState() => _MoveFormState();
}

class _MoveFormState extends ConsumerState<_MoveForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late _Destination? _to = widget.destinations.firstOrNull;
  bool _busy = false;
  String? _error;

  /// One key per distinct request, reused when retrying the same one.
  ({String key, String fingerprint})? _attempt;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final l10n = context.l10n;
    final basic = validateAmount(value, l10n);
    if (basic != null) return basic;
    return parseAmount(value!)! > widget.available
        ? l10n.amountTooHigh(formatTzs(widget.available))
        : null;
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final repository = ref.read(savingsRepositoryProvider);
    final amount = parseAmount(_amount.text)!;
    final note = trimmedOrNull(_note.text);
    final fingerprint = widget.withdraw
        ? 'w|$amount|$note'
        : 't|$amount|${_to?.id}';
    final attempt = _attempt;
    final key = attempt != null && attempt.fingerprint == fingerprint
        ? attempt.key
        : const Uuid().v4();
    _attempt = (key: key, fingerprint: fingerprint);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.withdraw) {
        await repository.withdraw(
          from: widget.fromGoalId,
          amount: amount,
          note: note,
          idempotencyKey: key,
        );
      } else {
        await repository.transfer(
          from: widget.fromGoalId,
          to: _to!.id,
          amount: amount,
          idempotencyKey: key,
        );
      }
      refreshSavingsData(ref);
      if (!mounted) return;
      showMessage(context, widget.withdraw ? l10n.withdrawDone : l10n.moveDone);
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      final available = (error.details['available'] as num?)?.toInt();
      setState(() {
        _busy = false;
        _error = error.errorCode == 'insufficient_funds' && available != null
            ? l10n.amountTooHigh(formatTzs(available))
            : describeError(error, l10n);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amount = parseAmount(_amount.text);
    final noDestination = !widget.withdraw && widget.destinations.isEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.moveFrom(widget.fromName, formatTzs(widget.available)),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [AmountInputFormatter()],
            validator: _validateAmount,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              labelText: l10n.depositAmountLabel,
              prefixText: 'TZS ',
              suffixIcon: TextButton(
                onPressed: () => setState(
                  () => _amount.text = formatGrouped(widget.available),
                ),
                child: Text(l10n.amountAll),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.withdraw) ...[
            TextFormField(
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.withdrawNote),
            ),
            Text(
              l10n.withdrawExplain,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (noDestination)
            Text(l10n.moveNoDestination)
          else ...[
            Text(l10n.moveTo, style: theme.textTheme.titleSmall),
            RadioGroup<_Destination>(
              groupValue: _to,
              onChanged: (value) => setState(() => _to = value),
              child: Column(
                children: [
                  for (final d in widget.destinations)
                    RadioListTile<_Destination>(
                      value: d,
                      title: Text(d.name),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FormError(_error),
          FilledButton(
            onPressed: _busy || noDestination ? null : _submit,
            child: _busy
                ? const ButtonSpinner()
                : Text(
                    widget.withdraw
                        ? l10n.withdrawSubmit(formatTzs(amount ?? 0))
                        : l10n.moveSubmit(formatTzs(amount ?? 0)),
                  ),
          ),
        ],
      ),
    );
  }
}
