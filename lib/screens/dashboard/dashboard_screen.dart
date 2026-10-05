import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/recommendations.dart';
import '../../providers/credits_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../domain/bank_detector.dart';
import '../../widgets/kredit_logo.dart';
import '../../widgets/kredit_section_card.dart';
import '../../widgets/progress_ring.dart';
import '../stats/simulator_sheet.dart';

/// Dashboard ("Inicio") screen — answers "¿Qué tengo que pagar pronto?":
/// a greeting header, 3 compact metrics (por pagar / créditos activos /
/// deuda total), up to 3 upcoming-payment cards sorted by urgency, and the
/// list of active credits below.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);
    final credits = creditsAsync.valueOrNull;
    final isEmpty = credits != null && credits.isEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: creditsAsync.when(
          loading: () => const _DashboardLoadingState(),
          error: (err, st) => _DashboardErrorState(
            onRetry: () => ref.invalidate(creditsProvider),
          ),
          data: (credits) => _DashboardBody(credits: credits),
        ),
      ),
      // Oculto cuando la lista está vacía: en ese estado `_EmptyDashboard`
      // ya muestra su propio botón "Nuevo Crédito" y tener ambos era una
      // acción duplicada en pantalla.
      floatingActionButton: isEmpty
          ? null
          : Builder(
              builder: (context) {
                // Bug 2: luminance-based foreground so icon is readable on any accent
                final accentColor = Theme.of(context).colorScheme.primary;
                final fgColor = legibleForegroundOn(accentColor);
                return FloatingActionButton(
                  // Explicit, distinct hero tag: with all 4 tabs kept alive by
                  // the root IndexedStack (see main.dart), this FAB and
                  // credits_list_screen.dart's FAB both exist in the tree at
                  // once — without distinct tags they'd collide on Flutter's
                  // default hero tag and throw "multiple heroes share the
                  // same tag".
                  heroTag: 'fab-dashboard',
                  backgroundColor: accentColor,
                  foregroundColor: fgColor,
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/add-credit'),
                  tooltip: 'Agregar Crédito',
                  child: const Icon(Icons.add),
                );
              },
            ),
    );
  }
}

/// Branded loading spinner shown while credits are first fetched — matches
/// the treatment used in credits_list_screen.dart / stats_screen.dart.
class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Error placeholder with icon + message + retry action, so a load failure
/// doesn't surface as raw debug text on the dashboard.
class _DashboardErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: KreditIconSize.large,
              color: kredit.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus créditos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                color: kredit.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: KreditIconSize.small),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting shown up top, keyed off the hour of day — the dashboard's main
/// textual element now that the AppBar has been collapsed to zero height.
/// Ranges: mañana 5:00–11:59, tarde 12:00–17:59, noche 18:00–4:59 (cubre
/// toda la franja nocturna/madrugada).
// Cacheado al abrir la app — cambia como máximo una vez por sesión.
final _greeting = () {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Buenos días';
  if (hour >= 12 && hour < 18) return 'Buenas tardes';
  return 'Buenas noches';
}();

class _DashboardBody extends ConsumerWidget {
  final List<Credit> credits;

  const _DashboardBody({required this.credits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (credits.isEmpty) {
      return const _EmptyDashboard();
    }
    final kredit = Theme.of(context).extension<KreditColors>()!;

    // select() rebuilds only when these values change, not on every theme save.
    final profileName = ref.watch(
      themePreferencesProvider.select((p) => p.profileName),
    );
    final avatarPath = ref.watch(
      themePreferencesProvider.select((p) => p.avatarPath),
    );
    final totalDebt = ref.watch(totalUnpaidProvider);
    // Pre-computed by dashboardDataProvider; returns null only transiently
    // before the first credits emission, which never happens here because
    // _DashboardBody is only rendered from the AsyncData branch.
    final data = ref.watch(dashboardDataProvider)!;
    final activeCredits = data.activeCredits;
    final progressPct = data.progressPct;
    final upcoming = data.upcoming;
    final weekSummary = data.weekSummary;
    final recommendation = data.recommendation;

    return ListView(
      // Extra bottom clearance so the last row of content can scroll clear
      // of the floating "+" button instead of sitting hidden behind it.
      padding: const EdgeInsets.fromLTRB(
        KreditSpacing.card,
        KreditSpacing.card,
        KreditSpacing.card,
        88,
      ),
      children: [
        // 1. Greeting header: foto de perfil a la izquierda + saludo + logo.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar circular — si no hay foto, muestra inicial del nombre.
            GestureDetector(
              onTap: () => ref.read(navigationIndexProvider.notifier).state =
                  AppNavTab.account,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.18),
                backgroundImage: avatarPath != null
                    ? FileImage(File(avatarPath))
                    : null,
                child: avatarPath == null
                    ? Text(
                        (profileName.isNotEmpty
                            ? profileName[0].toUpperCase()
                            : '?'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_greeting, $profileName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu situación crediticia',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const KreditLogo(height: 26),
          ],
        ),
        const SizedBox(height: 28),

        // 2. Panel de métricas con barra de progreso contextual bajo la cifra.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEUDA TOTAL',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCOP(totalDebt),
                    style: const TextStyle(
                      fontSize: KreditTextSize.hero,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            RepaintBoundary(
              child: ProgressRing(percent: progressPct, size: 68),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SecondaryStat(
                label: 'Por pagar · 7 días',
                value: formatCOP(weekSummary.dueWithin7Days),
              ),
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: kredit.borderCard,
            ),
            Expanded(
              child: _SecondaryStat(
                label: 'Créditos activos',
                value: '${activeCredits.length} de ${credits.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: KreditSpacing.section),

        // 3. Prioridad de hoy — el dashboard deja de ser solo un reporte y
        // empieza a comportarse como una guía: identifica el pago más urgente
        // y ofrece la acción natural para resolverlo.
        _PaymentCoachCard(
          recommendation: recommendation,
        ),

        // 5. Lista unificada de créditos activos con pago próximo integrado.
        if (activeCredits.isNotEmpty) ...[
          const SizedBox(height: KreditSpacing.section),
          _CreditsSectionCard(
            credits: activeCredits,
            upcoming: upcoming,
            onSeeAll: () =>
                ref.read(navigationIndexProvider.notifier).state =
                    AppNavTab.credits,
          ),
        ],

        // Fase 6 del roadmap: el simulador tambien accesible desde el
        // dashboard, no solo desde detalle del credito y Estadisticas —
        // mismo patron visual que `_SimulatorEntryRow` en stats_screen.dart
        // (no se pudo reutilizar directamente por ser una clase privada de
        // ese archivo, asi que se replica aqui en vez de exportarla, para
        // no acoplar dos pantallas por un widget tan chico).
        if (activeCredits.isNotEmpty) ...[
          const SizedBox(height: KreditSpacing.section),
          KreditSectionCard(
            children: [
              // Material transparente: KreditSectionCard pinta su fondo con
              // un DecoratedBox (no un Material), así que el ink splash del
              // ListTile pintaba en el Material ancestro más cercano (mucho
              // más arriba en el árbol) y quedaba oculto detrás de esa caja
              // — "ListTile background color or ink splashes may be
              // invisible" (warning real de Flutter, verificado en
              // dispositivo). Con este Material de por medio, el splash
              // pinta encima de la caja como corresponde.
              Material(
                color: Colors.transparent,
                child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => openSimulatorSheet(context),
                leading: Icon(Icons.calculate_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text(
                  '¿Qué pasa si…?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body),
                ),
                subtitle: Text(
                  'Simula una compra en cuotas o un abono extra a capital',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary),
                ),
                trailing: Icon(Icons.chevron_right, color: kredit.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Secondary metric expressed purely through typography — a small caps
/// label over a mid-weight value, no surrounding box. Jerarquía viene del
/// contraste de tamaño/peso frente a la cifra protagonista de arriba, no de
/// un contenedor propio.
class _SecondaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SecondaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: KreditTextSize.heading,
            letterSpacing: -0.3,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: KreditTextSize.body,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: kredit.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


class _PaymentCoachCard extends ConsumerWidget {
  final FinancialRecommendation recommendation;

  const _PaymentCoachCard({
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final fgOnAccent = legibleForegroundOn(accent);
    final item = recommendation.payment;

    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(KreditSpacing.card),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.card),
          border: Border.all(color: kredit.borderCard),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kredit.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(KreditRadius.tile),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: KreditIconSize.small,
                color: kredit.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prioridad de hoy',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'No tienes pagos pendientes por resolver.',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final daysLeft = item.daysUntilDue();
    final isLoan = item.installment != null;
    final urgencyColor = _severityColor(
      context,
      recommendation.severity,
    );
    final urgencyBg = urgencyColor.withValues(alpha: 0.14);
    final relativeLabel = formatRelativeDate(item.dueDate);

    return Container(
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(KreditRadius.tile),
                ),
                child: Icon(
                  daysLeft < 0
                      ? Icons.priority_high_rounded
                      : Icons.payments_outlined,
                  size: KreditIconSize.small,
                  color: urgencyColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: kredit.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.credit.name,
                      style: const TextStyle(
                        fontSize: KreditTextSize.heading,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCOP(item.amount),
                    style: const TextStyle(
                      fontSize: KreditTextSize.heading,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    relativeLabel,
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: urgencyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: KreditTextSize.body,
              color: kredit.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed('/credit-detail', arguments: item.credit.id),
                  icon: const Icon(
                    Icons.open_in_new,
                    size: KreditIconSize.small,
                  ),
                  label: const Text('Ver detalle'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: accent,
                    foregroundColor: fgOnAccent,
                  ),
                ),
              ),
              if (isLoan) ...[
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Marcar cuota como pagada',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(creditsProvider.notifier)
                        .toggleInstallmentPaid(
                          item.credit.id,
                          item.installment!.number,
                        );
                  },
                  icon: const Icon(Icons.done, size: KreditIconSize.small),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(42, 42),
                    foregroundColor: kredit.textPrimary,
                    side: BorderSide(color: kredit.borderCard),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Color _severityColor(
  BuildContext context,
  RecommendationSeverity severity,
) {
  final kredit = Theme.of(context).extension<KreditColors>()!;
  final accent = Theme.of(context).colorScheme.primary;
  return switch (severity) {
    RecommendationSeverity.calm => kredit.success,
    RecommendationSeverity.info => accent,
    RecommendationSeverity.warning => kredit.warning,
    RecommendationSeverity.danger => kredit.danger,
  };
}

/// Fila unificada de crédito: dot del banco · nombre + entidad + urgencia ·
/// métrica clave + chip "Marcar pago" (préstamos con pago próximo).
class _CreditListRow extends StatelessWidget {
  final Credit credit;
  final VoidCallback onTap;
  final PendingPayment? nextPayment;
  final void Function(String creditId, int installmentNumber)? onTogglePaid;

  const _CreditListRow({
    required this.credit,
    required this.onTap,
    this.nextPayment,
    this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final bank = detectBank(lender: credit.lender);
    final hex = bank.accentColor.replaceFirst('#', '');
    final bankColor = hex.length == 6
        ? Color(int.parse('FF$hex', radix: 16))
        : Theme.of(context).colorScheme.primary;

    final isCard = credit is CardCredit;
    final isLoan = credit is LoanCredit;

    final String metricValue;
    if (isCard) {
      metricValue = formatCOP((credit as CardCredit).currentBalance);
    } else {
      final remaining =
          (credit as LoanCredit).installments.where((i) => !i.paid).length;
      metricValue = '$remaining';
    }

    // Urgencia del próximo pago
    Color? urgencyColor;
    String? urgencyLabel;
    if (nextPayment != null) {
      final daysLeft = nextPayment!.daysUntilDue();
      if (daysLeft < 0) {
        urgencyColor = AppColors.danger;
        urgencyLabel = 'Vencido hace ${daysLeft.abs()}d';
      } else if (daysLeft == 0) {
        urgencyColor = Colors.orange;
        urgencyLabel = '¡Vence hoy!';
      } else if (daysLeft <= 3) {
        urgencyColor = Colors.amber;
        urgencyLabel = 'En $daysLeft días';
      } else {
        urgencyColor = kredit.textTertiary;
        urgencyLabel = 'En $daysLeft días';
      }
    }

    final typeLabel = isCard ? 'Tarjeta' : isLoan ? 'Préstamo' : 'Crédito';
    final subtitleParts = [bank.shortLabel, typeLabel];
    if (urgencyLabel != null) subtitleParts.add(urgencyLabel);

    final showMarkPaid = isLoan &&
        nextPayment != null &&
        nextPayment!.installment != null &&
        onTogglePaid != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: bankColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    credit.name,
                    style: const TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitleParts.join(' · '),
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: urgencyColor ?? kredit.textTertiary,
                      fontWeight: urgencyLabel != null
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metricValue,
                  style: const TextStyle(
                    fontSize: KreditTextSize.body,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                if (showMarkPaid)
                  Builder(builder: (ctx) {
                    final accentColor = Theme.of(ctx).colorScheme.primary;
                    final fgColor = legibleForegroundOn(accentColor);
                    final paid = nextPayment!.installment!.paid;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onTogglePaid!(
                          credit.id,
                          nextPayment!.installment!.number,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paid
                              ? kredit.success.withValues(alpha: 0.16)
                              : accentColor,
                          borderRadius:
                              BorderRadius.circular(KreditRadius.chip),
                        ),
                        child: Text(
                          paid ? 'Pagado' : 'Marcar pago',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w700,
                            color: paid ? kredit.success : fgColor,
                          ),
                        ),
                      ),
                    );
                  })
                else
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: kredit.textTertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección unificada: encabezado "Tus créditos" + filas ordenadas por urgencia
/// de pago, con chip "Marcar pago" integrado en cada fila de préstamo.
class _CreditsSectionCard extends ConsumerWidget {
  final List<Credit> credits;
  final List<PendingPayment> upcoming;
  final VoidCallback onSeeAll;

  const _CreditsSectionCard({
    required this.credits,
    required this.upcoming,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;

    PendingPayment? nextFor(Credit c) =>
        upcoming.where((p) => p.credit.id == c.id).firstOrNull;

    final sorted = [...credits]..sort((a, b) {
      final pa = nextFor(a);
      final pb = nextFor(b);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pa.daysUntilDue().compareTo(pb.daysUntilDue());
    });

    return KreditSectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Tus créditos',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: KreditTextSize.heading,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${credits.length}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w600,
                color: kredit.textTertiary,
              ),
            ),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onSeeAll,
              child: const Text(
                'Ver todos',
                style: TextStyle(fontSize: KreditTextSize.body),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) Divider(height: 1, color: kredit.borderCard),
          _CreditListRow(
            credit: sorted[i],
            nextPayment: nextFor(sorted[i]),
            onTogglePaid:
                ref.read(creditsProvider.notifier).toggleInstallmentPaid,
            onTap: () => Navigator.of(context).pushNamed(
              '/credit-detail',
              arguments: sorted[i].id,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: KreditIconSize.large,
              color: kredit.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes créditos registrados',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: KreditTextSize.body,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera tarjeta o préstamo para empezar a llevar el control.',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                color: kredit.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/add-credit'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Crédito'),
            ),
          ],
        ),
      ),
    );
  }
}

