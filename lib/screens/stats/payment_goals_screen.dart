import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/credit.dart';
import '../../domain/credit_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PaymentGoal {
  final String id;
  final String creditId;
  final String creditName;
  final double targetAmount;
  final DateTime deadline;
  final DateTime createdAt;

  const PaymentGoal({
    required this.id,
    required this.creditId,
    required this.creditName,
    required this.targetAmount,
    required this.deadline,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'creditId': creditId,
        'creditName': creditName,
        'targetAmount': targetAmount,
        'deadline': deadline.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PaymentGoal.fromJson(Map<String, dynamic> j) => PaymentGoal(
        id: j['id'] as String,
        creditId: j['creditId'] as String,
        creditName: j['creditName'] as String? ?? '',
        targetAmount: (j['targetAmount'] as num).toDouble(),
        deadline: DateTime.parse(j['deadline'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

const _kPrefsKey = 'payment_goals';

class GoalsNotifier extends AsyncNotifier<List<PaymentGoal>> {
  @override
  Future<List<PaymentGoal>> build() async => _load();

  Future<List<PaymentGoal>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PaymentGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PaymentGoal goal) async {
    final current = state.value ?? [];
    final updated = [...current, goal];
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> remove(String id) async {
    final current = state.value ?? [];
    final updated = current.where((g) => g.id != id).toList();
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> _persist(List<PaymentGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kPrefsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }
}

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<PaymentGoal>>(GoalsNotifier.new);

// ── Status helper ─────────────────────────────────────────────────────────────

enum GoalStatus { achieved, onTrack, atRisk }

GoalStatus _goalStatus(PaymentGoal goal, double remaining) {
  if (remaining <= 0) return GoalStatus.achieved;
  final now = DateTime.now();
  final daysLeft = goal.deadline.difference(now).inDays;
  if (daysLeft <= 0) return GoalStatus.atRisk;
  // Estimate daily reduction needed; compare to typical 30-day minimum
  final totalDays = goal.deadline.difference(goal.createdAt).inDays;
  if (totalDays <= 0) return GoalStatus.atRisk;
  final elapsed = now.difference(goal.createdAt).inDays;
  final expectedRemaining =
      goal.targetAmount * (1 - elapsed / totalDays).clamp(0, 1);
  return remaining <= expectedRemaining * 1.15 ? GoalStatus.onTrack : GoalStatus.atRisk;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PaymentGoalsScreen extends ConsumerWidget {
  const PaymentGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas de pago')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final credits = creditsAsync.value ?? [];
          if (credits.isEmpty) return;
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddGoalSheet(credits: credits),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) return const _EmptyState();
          final credits = creditsAsync.value ?? [];
          final creditMap = {for (final c in credits) c.id: c};
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                KreditSpacing.card, KreditSpacing.card, KreditSpacing.card, 96),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final goal = goals[i];
              final credit = creditMap[goal.creditId];
              final remaining = credit != null
                  ? getCreditRemainingBalance(credit)
                  : goal.targetAmount;
              return _GoalCard(
                goal: goal,
                remaining: remaining,
                onDelete: () => ref.read(goalsProvider.notifier).remove(goal.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final PaymentGoal goal;
  final double remaining;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.remaining,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final now = DateTime.now();
    final daysLeft = goal.deadline.difference(now).inDays;
    final status = _goalStatus(goal, remaining);
    final progress =
        ((goal.targetAmount - remaining) / goal.targetAmount).clamp(0.0, 1.0);

    final (statusLabel, statusColor) = switch (status) {
      GoalStatus.achieved => ('Lograda', kredit.success),
      GoalStatus.onTrack => ('En camino', kredit.info),
      GoalStatus.atRisk => ('En riesgo', kredit.danger),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.creditName,
                  style: const TextStyle(
                    fontSize: KreditTextSize.heading,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(KreditRadius.chip),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline,
                    size: KreditIconSize.small, color: kredit.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meta: ${formatCOP(goal.targetAmount)}',
                      style: TextStyle(
                        color: kredit.textSecondary,
                        fontSize: KreditTextSize.body,
                      ),
                    ),
                    Text(
                      'Restante: ${formatCOP(remaining.clamp(0, double.infinity))}',
                      style: TextStyle(
                        color: kredit.textPrimary,
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                status == GoalStatus.achieved
                    ? '¡Meta cumplida!'
                    : daysLeft > 0
                        ? '$daysLeft días restantes'
                        : 'Venció hace ${(-daysLeft)} días',
                style: TextStyle(
                  color: daysLeft <= 0 && status != GoalStatus.achieved
                      ? kredit.danger
                      : kredit.textTertiary,
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: kredit.borderCard,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fecha límite: ${_fmtDate(goal.deadline)}',
            style: TextStyle(
                color: kredit.textTertiary, fontSize: KreditTextSize.caption),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ── Add goal sheet ─────────────────────────────────────────────────────────────

class _AddGoalSheet extends ConsumerStatefulWidget {
  final List<Credit> credits;
  const _AddGoalSheet({required this.credits});

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  Credit? _selected;
  final _amountCtrl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final credit = _selected;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (credit == null) {
      setState(() => _error = 'Selecciona un crédito');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    if (_deadline == null) {
      setState(() => _error = 'Selecciona una fecha límite');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(goalsProvider.notifier).add(PaymentGoal(
          id: const Uuid().v4(),
          creditId: credit.id,
          creditName: credit.name,
          targetAmount: amount,
          deadline: _deadline!,
          createdAt: DateTime.now(),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(KreditRadius.card)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nueva meta de pago',
            style: TextStyle(
              fontSize: KreditTextSize.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // Credit picker
          DropdownButtonFormField<Credit>(
            value: _selected,
            decoration: InputDecoration(
              labelText: 'Crédito',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KreditRadius.tile)),
            ),
            items: widget.credits
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (c) => setState(() => _selected = c),
          ),
          const SizedBox(height: 14),

          // Target amount
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto meta (COP)',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KreditRadius.tile)),
            ),
          ),
          const SizedBox(height: 14),

          // Deadline
          GestureDetector(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha límite',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KreditRadius.tile)),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _deadline != null ? _fmtDate(_deadline!) : 'Seleccionar fecha',
                style: TextStyle(
                  color: _deadline != null
                      ? kredit.textPrimary
                      : kredit.textTertiary,
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: kredit.danger, fontSize: KreditTextSize.body),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar meta'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: KreditIconSize.large, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Sin metas de pago',
              style: TextStyle(
                fontSize: KreditTextSize.heading,
                fontWeight: FontWeight.bold,
                color: kredit.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una meta para trackear tu progreso hacia un objetivo de pago concreto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
