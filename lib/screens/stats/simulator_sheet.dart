import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card_movement.dart';
import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../domain/interest_rate.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../utils/currency_input_formatter.dart';
import '../../widgets/kredit_bottom_dialogs.dart';

part 'simulator_sheet_widgets.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Escenarios con nombre — persistencia via SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

class _NamedScenario {
  final String id;
  final String nombre;
  final String fecha;
  final String tipo; // 'compra' | 'abono'
  final String resumen;

  const _NamedScenario({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.tipo,
    required this.resumen,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'fecha': fecha,
        'tipo': tipo,
        'resumen': resumen,
      };

  factory _NamedScenario.fromJson(Map<String, dynamic> j) => _NamedScenario(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        fecha: j['fecha'] as String,
        tipo: j['tipo'] as String,
        resumen: j['resumen'] as String,
      );
}

const _namedScenariosKey = 'simulator_named_scenarios';
const _maxNamedScenarios = 10;

Future<List<_NamedScenario>> _loadNamedScenarios() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_namedScenariosKey);
  if (raw == null) return [];
  return (jsonDecode(raw) as List)
      .map((e) => _NamedScenario.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> _saveNamedScenario(_NamedScenario scenario) async {
  final prefs = await SharedPreferences.getInstance();
  final list = await _loadNamedScenarios();
  list.insert(0, scenario);
  if (list.length > _maxNamedScenarios) list.removeRange(_maxNamedScenarios, list.length);
  await prefs.setString(_namedScenariosKey, jsonEncode(list.map((s) => s.toJson()).toList()));
}

Future<void> _deleteNamedScenario(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final list = await _loadNamedScenarios();
  list.removeWhere((s) => s.id == id);
  await prefs.setString(_namedScenariosKey, jsonEncode(list.map((s) => s.toJson()).toList()));
}

// ── Freedom tab helpers ───────────────────────────────────────────────────────

String _monthsToDateStr(int months) {
  if (months <= 0) return 'Ya saldado';
  if (months >= 600) return 'Más de 50 años';
  final date = DateTime.now().add(Duration(days: months * 30));
  const names = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  return '${names[date.month - 1]} ${date.year}';
}

String _monthsLabel(int months) {
  if (months <= 0) return 'saldado';
  if (months == 1) return '1 mes';
  return '$months meses';
}

double _remainingBalanceOf(Credit credit) {
  if (credit is LoanCredit) return getLoanRemainingPrincipal(credit);
  if (credit is CardCredit) return credit.currentBalance;
  return 0;
}

double _remainingInterestOf(Credit credit) {
  if (credit is LoanCredit) {
    return credit.installments
        .where((i) => !i.paid)
        .fold(0.0, (s, i) => s + i.interest);
  }
  if (credit is CardCredit) {
    final dailyRate =
        credit.interestRate > 0 ? credit.interestRate / 100 / 365 : 0.0;
    final monthlyRate = dailyRate * 30;
    var balance = credit.currentBalance;
    var totalInterest = 0.0;
    var months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthlyRate;
      totalInterest += interest;
      final minPay = math.max(balance * 0.02, 50000.0);
      if (minPay >= balance + interest) break;
      balance = balance + interest - minPay;
      months++;
    }
    return totalInterest;
  }
  return 0;
}

double _monthlyBaseOf(Credit credit) {
  if (credit is LoanCredit) return credit.quotaAmount;
  if (credit is CardCredit) return math.max(credit.currentBalance * 0.02, 50000.0);
  return 0;
}

double _interestRateOf(Credit c) {
  if (c is LoanCredit) return c.interestRate;
  if (c is CardCredit) return c.interestRate;
  return 0;
}

int _monthsWithPayment(Credit credit, double monthlyPayment) {
  if (monthlyPayment <= 0) return 600;
  if (credit is LoanCredit) {
    final unpaid = credit.installments.where((i) => !i.paid).toList();
    if (unpaid.isEmpty) return 0;
    final balance = unpaid.fold(0.0, (s, i) => s + i.principal);
    if (balance <= 0) return 0;
    final periodRate = periodicRateFrom(
        credit.interestRate, credit.interestRateType, credit.frequency);
    if (periodRate <= 0) return (balance / monthlyPayment).ceil().clamp(1, 600);
    if (monthlyPayment <= balance * periodRate) return 600;
    final n =
        math.log(monthlyPayment / (monthlyPayment - balance * periodRate)) /
            math.log(1 + periodRate);
    if (n.isNaN || n.isInfinite || n < 0) return 600;
    return n.ceil().clamp(1, 600);
  }
  if (credit is CardCredit) {
    var balance = credit.currentBalance;
    if (balance <= 0) return 0;
    final dailyRate =
        credit.interestRate > 0 ? credit.interestRate / 100 / 365 : 0.0;
    final monthlyRate = dailyRate * 30;
    var months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthlyRate;
      final payment =
          math.max(monthlyPayment, math.max(balance * 0.02, 50000.0));
      if (payment >= balance + interest) {
        months++;
        break;
      }
      balance = balance + interest - payment;
      months++;
    }
    return months;
  }
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point: abre el sheet
// ─────────────────────────────────────────────────────────────────────────────

void openSimulatorSheet(BuildContext context, {String? initialCreditId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SimulatorSheet(initialCreditId: initialCreditId),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet principal
// ─────────────────────────────────────────────────────────────────────────────

class SimulatorSheet extends ConsumerStatefulWidget {
  final String? initialCreditId;
  const SimulatorSheet({super.key, this.initialCreditId});

  @override
  ConsumerState<SimulatorSheet> createState() => _SimulatorSheetState();
}

class _SimulatorSheetState extends ConsumerState<SimulatorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    // Sin crédito específico → abrir en Libertad (tab 2) para mostrar visión global.
    // Con crédito específico → Abonar extra (1) para préstamos, Simular compra (0) para tarjetas.
    final initialIndex = widget.initialCreditId != null
        ? () {
            final credits =
                ref.read(creditsProvider).valueOrNull ?? const <Credit>[];
            final match =
                credits.where((c) => c.id == widget.initialCreditId).toList();
            if (match.isNotEmpty && match.first is LoanCredit) return 1;
            return 0;
          }()
        : 2;
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final creditsAsync = ref.watch(creditsProvider);
    final credits = creditsAsync.valueOrNull ?? [];

    final accent = Theme.of(context).colorScheme.primary;
    final activeCredits = credits.where((c) {
      if (c is LoanCredit) return c.installments.any((i) => !i.paid);
      if (c is CardCredit) return c.currentBalance > 0;
      return false;
    }).toList();
    final baseline =
        activeCredits.isNotEmpty ? _computeFreedom(activeCredits, 0, true) : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: KreditIconSize.small, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulador financiero',
                    style: TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stat strip: snapshot rápido de toda la deuda activa
          if (baseline != null && baseline.rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DebtSnapshotStrip(baseline: baseline, kredit: kredit, accent: accent),
          ] else ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 20),
              child: Text(
                '¿Qué pasaría si…? Resultados aproximados.',
                style: TextStyle(
                    fontSize: KreditTextSize.body, color: kredit.textTertiary),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Tabs
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.shopping_cart_outlined, size: KreditIconSize.small), text: 'Simular compra'),
              Tab(icon: Icon(Icons.payments_outlined, size: KreditIconSize.small), text: 'Abonar extra'),
              Tab(icon: Icon(Icons.rocket_launch_outlined, size: KreditIconSize.small), text: 'Libertad'),
            ],
          ),
          // Content — cada tab maneja su propio ScrollController para evitar
          // el error de AccessibilityBridge al compartir un mismo controller
          // entre múltiples ListView montados simultáneamente en TabBarView.
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _PurchaseTab(credits: credits),
                _ExtraPaymentTab(
                  credits: credits,
                  initialCreditId: widget.initialCreditId,
                ),
                _FreedomTab(credits: credits),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

