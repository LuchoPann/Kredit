import 'dart:math' as math;

import '../data/models/credit.dart';
import '../data/models/installment.dart';
import 'card_calculator.dart';
import 'credit_calculator.dart';
import 'date_utils.dart';
import 'interest_rate.dart';
import 'urgency_score.dart';

enum RecommendationSeverity { calm, info, warning, danger }

class PendingPayment {
  final Credit credit;
  final DateTime dueDate;
  final Installment? installment;

  PendingPayment({
    required this.credit,
    required this.dueDate,
    this.installment,
  });

  bool get isLoanInstallment => installment != null;

  double get amount {
    if (installment != null) return installment!.amount;
    final c = credit;
    return c is CardCredit ? c.currentBalance : 0;
  }

  int daysUntilDue([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  double urgency([DateTime? now]) {
    return urgencyScore(daysUntilDue: daysUntilDue(now), amount: amount);
  }
}

class PaymentWeekSummary {
  final double dueWithin7Days;
  final int overdueCount;
  final int dueTodayCount;
  final int dueSoonCount;
  final PendingPayment? nextPayment;

  const PaymentWeekSummary({
    required this.dueWithin7Days,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.dueSoonCount,
    required this.nextPayment,
  });

  int get actionCount => overdueCount + dueTodayCount;
}

class FinancialRecommendation {
  final String title;
  final String description;
  final RecommendationSeverity severity;
  final PendingPayment? payment;

  const FinancialRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    this.payment,
  });
}

List<PendingPayment> buildPendingPayments(
  List<Credit> credits, {
  DateTime? now,
}) {
  final items = <PendingPayment>[];
  for (final c in credits) {
    if (c is LoanCredit) {
      final unpaid = c.installments.where((i) => !i.paid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (unpaid.isNotEmpty) {
        items.add(
          PendingPayment(
            credit: c,
            dueDate: parseDateStr(unpaid.first.dueDate),
            installment: unpaid.first,
          ),
        );
      }
    } else if (c is CardCredit && c.currentBalance > 0) {
      items.add(PendingPayment(credit: c, dueDate: getCardCycleDates(c).dueDate));
    }
  }
  items.sort((a, b) => b.urgency(now).compareTo(a.urgency(now)));
  return items;
}

PaymentWeekSummary buildPaymentWeekSummary(
  List<PendingPayment> payments, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final horizon = today.add(const Duration(days: 7));
  var dueWithin7Days = 0.0;
  var overdueCount = 0;
  var dueTodayCount = 0;
  var dueSoonCount = 0;

  PendingPayment? nextPayment;
  for (final payment in payments) {
    final due = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );
    final days = payment.daysUntilDue(today);
    if (days < 0) overdueCount++;
    if (days == 0) dueTodayCount++;
    if (days > 0 && days <= 7) dueSoonCount++;
    if (!due.isAfter(horizon)) dueWithin7Days += payment.amount;
    if (nextPayment == null || due.isBefore(nextPayment.dueDate)) {
      nextPayment = payment;
    }
  }

  return PaymentWeekSummary(
    dueWithin7Days: dueWithin7Days,
    overdueCount: overdueCount,
    dueTodayCount: dueTodayCount,
    dueSoonCount: dueSoonCount,
    nextPayment: nextPayment,
  );
}

FinancialRecommendation buildPrimaryRecommendation(
  List<Credit> credits, {
  DateTime? now,
}) {
  final payments = buildPendingPayments(credits, now: now);
  if (payments.isEmpty) {
    return const FinancialRecommendation(
      title: 'Todo al dia',
      description: 'No tienes pagos pendientes por resolver.',
      severity: RecommendationSeverity.calm,
    );
  }

  final payment = payments.first;
  final days = payment.daysUntilDue(now);
  if (days < 0) {
    return FinancialRecommendation(
      title: 'Resolver pago vencido',
      description: 'Conviene pagar ${payment.credit.name} antes de revisar compromisos futuros.',
      severity: RecommendationSeverity.danger,
      payment: payment,
    );
  }
  if (days == 0) {
    return FinancialRecommendation(
      title: 'Pagar hoy',
      description: '${payment.credit.name} vence hoy. Si ya pagaste, marcalo para limpiar tu agenda.',
      severity: RecommendationSeverity.warning,
      payment: payment,
    );
  }
  if (days <= 3) {
    return FinancialRecommendation(
      title: 'Preparar pago cercano',
      description: '${payment.credit.name} esta dentro de la ventana critica de los proximos 3 dias.',
      severity: RecommendationSeverity.warning,
      payment: payment,
    );
  }

  return FinancialRecommendation(
    title: 'Siguiente compromiso',
    description: '${payment.credit.name} es el proximo pago en tu calendario.',
    severity: RecommendationSeverity.info,
    payment: payment,
  );
}

/// Fase 9 / Tarea 5 del roadmap ("Motor avanzado de recomendaciones"):
/// reglas que comparan créditos entre sí en vez de mirar uno a la vez —
/// complementa a `buildPrimaryRecommendation` (que solo mira el pago más
/// urgente) con riesgos que solo se ven al comparar el conjunto completo.
List<FinancialRecommendation> buildRiskRecommendations(
  List<Credit> credits, {
  DateTime? now,
}) {
  final risks = <FinancialRecommendation>[];

  // Riesgo 1: concentración — un solo acreedor representa la mayoría de tu
  // deuda pendiente, así que un problema con esa entidad te afecta entero.
  final balances = <Credit, double>{
    for (final c in credits)
      c: getCreditRemainingBalance(c),
  }..removeWhere((_, v) => v <= 0);
  final totalDebt = balances.values.fold<double>(0, (s, v) => s + v);
  if (totalDebt > 0 && balances.length > 1) {
    final topEntry = balances.entries.reduce((a, b) => b.value > a.value ? b : a);
    final share = topEntry.value / totalDebt;
    if (share >= 0.6) {
      risks.add(
        FinancialRecommendation(
          title: 'Deuda concentrada',
          description:
              '${(share * 100).round()}% de tu deuda pendiente esta en '
              '${topEntry.key.name} — si ese pago se complica, arrastra el '
              'resto de tu presupuesto.',
          severity: RecommendationSeverity.warning,
        ),
      );
    }
  }

  // Riesgo 2: tarjetas cerca del cupo — utilización alta sube el costo
  // financiero y reduce el margen para imprevistos.
  for (final c in credits) {
    if (c is! CardCredit || c.creditLimit <= 0) continue;
    final utilization = c.currentBalance / c.creditLimit;
    if (utilization >= 0.85) {
      risks.add(
        FinancialRecommendation(
          title: 'Cupo casi agotado',
          description:
              '${c.name} esta al ${(utilization * 100).round()}% de su cupo '
              '— te queda poco margen para un gasto imprevisto.',
          severity: RecommendationSeverity.warning,
        ),
      );
    }
  }

  // Riesgo 3: deuda mas costosa — un credito activo con una tasa mucho mas
  // alta que el resto encarece el conjunto aunque su saldo no sea el mayor.
  final rated = <Credit, double>{
    for (final c in credits)
      if (getCreditRemainingBalance(c) > 0) c: effectiveAnnualRate(c),
  }..removeWhere((_, r) => r <= 0);
  if (rated.length > 1) {
    final costliest = rated.entries.reduce((a, b) => b.value > a.value ? b : a);
    final others = rated.entries.where((e) => e.key != costliest.key);
    final avgOthers = others.fold<double>(0, (s, e) => s + e.value) / others.length;
    if (costliest.value >= avgOthers * 1.5 && costliest.value >= 30) {
      risks.add(
        FinancialRecommendation(
          title: 'Deuda mas costosa',
          description:
              '${costliest.key.name} tiene una tasa efectiva anual de '
              '~${costliest.value.round()}%, muy por encima de tus otros '
              'creditos — es el que mas intereses te genera por cada peso '
              'pendiente.',
          severity: RecommendationSeverity.warning,
        ),
      );
    }
  }

  // Riesgo 4: mora acumulada — no requiere guardar historial nuevo (no hay
  // que migrar la base de datos): se calcula sobre los pagos vencidos AHORA
  // mismo, vistos en conjunto. Un solo pago vencido reciente es una alerta
  // normal (ya la cubre buildPrimaryRecommendation); esto dispara cuando el
  // problema ya es sistemico: varios creditos vencidos a la vez, o uno solo
  // muy atrasado. Severidad progresiva SOLO con datos de hoy (dias vencidos
  // actuales), sin necesitar un historial persistido de mora:
  //   - warning: 1 credito vencido entre 30 y 59 dias, o 2+ vencidos a la vez.
  //   - danger:  1 credito vencido 60+ dias, o 3+ vencidos a la vez.
  final payments = buildPendingPayments(credits, now: now);
  final overdue = payments.where((p) => p.daysUntilDue(now) < 0).toList();
  if (overdue.isNotEmpty) {
    final worstDays = overdue.map((p) => -p.daysUntilDue(now)).reduce(math.max);
    final overdueTotal = overdue.fold<double>(0, (s, p) => s + p.amount);
    final isSevere = overdue.length >= 3 || worstDays >= 60;
    final isModerate = overdue.length >= 2 || worstDays >= 30;
    if (isSevere || isModerate) {
      final plural = overdue.length == 1 ? '' : 's';
      risks.add(
        FinancialRecommendation(
          title: 'Mora acumulada',
          description: overdue.length >= 2
              ? 'Tienes ${overdue.length} pago$plural vencidos a la vez '
                  '(${_fmtCOP(overdueTotal)} en total) — el atraso se esta '
                  'acumulando en varios frentes, no solo en uno.'
              : '${overdue.first.credit.name} lleva $worstDays dias vencido '
                  '— entre mas tiempo pase, mas dificil es ponerse al dia.',
          severity: isSevere ? RecommendationSeverity.danger : RecommendationSeverity.warning,
        ),
      );
    }
  }

  return risks;
}

String _fmtCOP(double v) {
  final n = v.round().abs();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$${buf.toString()}';
}

/// Normaliza la tasa de un credito (loan o card, cualquier periodicidad
/// declarada) a una tasa efectiva anual comparable, reutilizando
/// `dailyRateFrom` de interest_rate.dart. Devuelve 0 para creditos sin tasa
/// registrada.
double effectiveAnnualRate(Credit credit) {
  final rate = credit is LoanCredit
      ? credit.interestRate
      : credit is CardCredit
          ? credit.interestRate
          : 0.0;
  if (rate <= 0) return 0;
  final rateType = credit is LoanCredit
      ? credit.interestRateType
      : credit is CardCredit
          ? credit.interestRateType
          : InterestRateType.effectiveAnnual;
  final daily = dailyRateFrom(rate, rateType);
  return (math.pow(1 + daily, 365) - 1) * 100;
}

/// Fase 6/9: entre los creditos activos (tipo prestamo, con cuotas
/// pendientes), cual conviene abonar primero — el de mayor tasa efectiva
/// anual es el que mas intereses evita por cada peso abonado de mas.
/// Devuelve null cuando hay menos de dos prestamos activos para comparar
/// (con uno solo no hay "primero" que elegir).
FinancialRecommendation? buildBestPrepaymentRecommendation(
  List<Credit> credits,
) {
  final loans = credits
      .whereType<LoanCredit>()
      .where((l) => l.installments.any((i) => !i.paid))
      .toList();
  if (loans.length < 2) return null;

  final best = loans.reduce(
    (a, b) => effectiveAnnualRate(b) > effectiveAnnualRate(a) ? b : a,
  );
  final rate = effectiveAnnualRate(best);
  if (rate <= 0) return null;

  return FinancialRecommendation(
    title: 'Conviene abonar primero',
    description:
        '${best.name} tiene la tasa efectiva anual mas alta de tus '
        'prestamos activos (~${rate.round()}%) — un abono extra ahi es '
        'donde mas interes te ahorras.',
    severity: RecommendationSeverity.info,
  );
}

String buildFinancialHealthLine(
  List<Credit> credits,
  PaymentWeekSummary summary,
) {
  if (credits.where(creditHasUnpaid).isEmpty) {
    return 'No tienes deuda activa registrada.';
  }
  if (summary.overdueCount > 0) {
    return 'Tienes ${summary.overdueCount} pago${summary.overdueCount == 1 ? '' : 's'} vencido${summary.overdueCount == 1 ? '' : 's'} por resolver.';
  }
  if (summary.dueTodayCount > 0) {
    return 'Tienes ${summary.dueTodayCount} pago${summary.dueTodayCount == 1 ? '' : 's'} para hoy.';
  }
  if (summary.dueSoonCount > 0) {
    return 'Tienes ${summary.dueSoonCount} compromiso${summary.dueSoonCount == 1 ? '' : 's'} en los proximos 7 dias.';
  }
  return 'Todo esta al dia para esta semana.';
}
