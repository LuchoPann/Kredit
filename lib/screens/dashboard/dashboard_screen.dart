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
import '../../widgets/attack_tools_sheet.dart';

/// Dashboard ("Inicio") screen — answers "¿Qué tengo que pagar pronto?":
/// a greeting header, 3 compact metrics (por pagar / créditos activos /
/// deuda total), up to 3 upcoming-payment cards sorted by urgency, and the
/// list of active credits below.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granular selectors: each rebuilds only the minimal subtree that needs it.
    final isLoading = ref.watch(creditsProvider.select((s) => s.isLoading));
    final hasError  = ref.watch(creditsProvider.select((s) => s.hasError));
    // isEmpty true while loading/error so FAB is hidden in those states too.
    final isEmpty   = ref.watch(creditsProvider.select((s) => s.value?.isEmpty ?? true));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const _DashboardLoadingState()
            : hasError
                ? _DashboardErrorState(
                    onRetry: () => ref.invalidate(creditsProvider),
                  )
                : const _DashboardBody(),
      ),
      // Oculto cuando la lista está vacía: en ese estado `_EmptyDashboard`
      // ya muestra su propio botón "Nuevo Crédito" y tener ambos era una
      // acción duplicada en pantalla.
      floatingActionButton: isEmpty
          ? null
          : Builder(
              builder: (context) {
                // Luminance-based foreground so icon is readable on any accent.
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppIconSize.large,
              color: kredit.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus créditos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSize.body,
                color: kredit.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: AppIconSize.small),
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
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-computed by dashboardDataProvider; null only transiently before
    // the first emission — _DashboardBody is only built when data is ready.
    final data = ref.watch(dashboardDataProvider);
    if (data == null) return const _EmptyDashboard();

    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final activeCredits = data.activeCredits;

    if (activeCredits.isEmpty && ref.watch(totalCreditsCountProvider) == 0) {
      return const _EmptyDashboard();
    }

    // select() rebuilds only when these values change, not on every theme save.
    final profileName = ref.watch(
      themePreferencesProvider.select((p) => p.profileName),
    );
    final avatarPath = ref.watch(
      themePreferencesProvider.select((p) => p.avatarPath),
    );
    final totalDebt = ref.watch(totalUnpaidProvider);
    // Selector: rebuilds "N de M" stat only when total count changes.
    final totalCount = ref.watch(totalCreditsCountProvider);
    final progressPct = data.progressPct;
    final upcoming = data.upcoming;
    final weekSummary = data.weekSummary;
    final recommendation = data.recommendation;

    return ListView(
      // Extra bottom clearance so the last row of content can scroll clear
      // of the floating "+" button instead of sitting hidden behind it.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.card,
        AppSpacing.card,
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
                      fontSize: AppTextSize.body,
                      color: kredit.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppLogo(height: 26),
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
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCOP(totalDebt),
                    style: const TextStyle(
                      fontSize: AppTextSize.hero,
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
                value: '${activeCredits.length} de $totalCount',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),

        // 3. Prioridad de hoy — el dashboard deja de ser solo un reporte y
        // empieza a comportarse como una guía: identifica el pago más urgente
        // y ofrece la acción natural para resolverlo.
        _PaymentCoachCard(
          recommendation: recommendation,
          credits: activeCredits,
          upcoming: upcoming,
          onSeeAll: () =>
              ref.read(navigationIndexProvider.notifier).state =
                  AppNavTab.credits,
        ),

        // Fase 6 del roadmap: el simulador tambien accesible desde el
        // dashboard, no solo desde detalle del credito y Estadisticas —
        // mismo patron visual que `_SimulatorEntryRow` en stats_screen.dart
        // (no se pudo reutilizar directamente por ser una clase privada de
        // ese archivo, asi que se replica aqui en vez de exportarla, para
        // no acoplar dos pantallas por un widget tan chico).
        if (activeCredits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          AppSectionCard(
            children: [
              // Material transparente: AppSectionCard pinta su fondo con
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.body),
                ),
                subtitle: Text(
                  'Simula una compra en cuotas o un abono extra a capital',
                  style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
                ),
                trailing: Icon(Icons.chevron_right, color: kredit.textTertiary),
                ),
              ),
              Divider(height: 1, color: kredit.borderCard),
              Material(
                color: Colors.transparent,
                child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => showAttackToolsSheet(context),
                leading: Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text(
                  'Herramientas de ataque',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.body),
                ),
                subtitle: Text(
                  'Snowball, Avalanche, metas y más',
                  style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppTextSize.heading,
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
            fontSize: AppTextSize.body,
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
  final List<Credit> credits;
  final List<PendingPayment> upcoming;
  final VoidCallback onSeeAll;

  const _PaymentCoachCard({
    required this.recommendation,
    required this.credits,
    required this.upcoming,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final fgOnAccent = legibleForegroundOn(accent);
    final item = recommendation.payment;

    final urgencyColor =
        item == null ? kredit.borderCard : _severityColor(context, recommendation.severity);
    final borderColor =
        item == null ? kredit.borderCard : urgencyColor.withValues(alpha: 0.28);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título del card ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Tus créditos',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextSize.heading,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${credits.length}',
                style: TextStyle(
                  fontSize: AppTextSize.body,
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
                  style: TextStyle(fontSize: AppTextSize.body),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: kredit.borderCard),
          const SizedBox(height: 12),

          // ── Siguiente compromiso ─────────────────────────────────────────
          if (item == null) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kredit.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: AppIconSize.small,
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
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'No tienes pagos pendientes por resolver.',
                        style: TextStyle(
                          fontSize: AppTextSize.body,
                          color: kredit.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            _NextPaymentBlock(
              item: item,
              recommendation: recommendation,
              urgencyColor: urgencyColor,
              accent: accent,
              fgOnAccent: fgOnAccent,
              onTogglePaid: (item.installment != null)
                  ? () {
                      HapticFeedback.mediumImpact();
                      ref.read(creditsProvider.notifier).toggleInstallmentPaid(
                            item.credit.id,
                            item.installment!.number,
                          );
                    }
                  : null,
            ),
          ],

          // ── Lista de créditos (sin el crédito ya mostrado arriba) ────────
          _CreditsListSection(
            credits: credits,
            upcoming: upcoming,
            priorityCreditId: item?.credit.id,
          ),
        ],
      ),
    );
  }
}

/// Bloque visual del pago prioritario dentro del card unificado.
class _NextPaymentBlock extends StatelessWidget {
  final PendingPayment item;
  final FinancialRecommendation recommendation;
  final Color urgencyColor;
  final Color accent;
  final Color fgOnAccent;
  final VoidCallback? onTogglePaid;

  const _NextPaymentBlock({
    required this.item,
    required this.recommendation,
    required this.urgencyColor,
    required this.accent,
    required this.fgOnAccent,
    this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final daysLeft = item.daysUntilDue();
    final relativeLabel = formatRelativeDate(item.dueDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Icon(
                daysLeft < 0 ? Icons.priority_high_rounded : Icons.payments_outlined,
                size: AppIconSize.small,
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
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.credit.name,
                    style: const TextStyle(
                      fontSize: AppTextSize.heading,
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
                    fontSize: AppTextSize.heading,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  relativeLabel,
                  style: TextStyle(
                    fontSize: AppTextSize.body,
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
            fontSize: AppTextSize.body,
            color: kredit.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/credit-detail', arguments: item.credit.id),
                icon: const Icon(Icons.open_in_new, size: AppIconSize.small),
                label: const Text('Ver detalle'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  backgroundColor: accent,
                  foregroundColor: fgOnAccent,
                ),
              ),
            ),
            if (onTogglePaid != null) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Marcar cuota como pagada',
                onPressed: onTogglePaid,
                icon: const Icon(Icons.done, size: AppIconSize.small),
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
    );
  }
}

Color _severityColor(
  BuildContext context,
  RecommendationSeverity severity,
) {
  final kredit = Theme.of(context).extension<AppThemeColors>()!;
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
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

    // Subtítulo: "Banco · N cuotas" o "Banco · $Xk saldo"
    final int? remaining = isLoan
        ? (credit as LoanCredit).installments.where((i) => !i.paid).length
        : null;
    final subtitleParts = [bank.shortLabel];
    if (remaining != null) {
      subtitleParts.add('$remaining ${remaining == 1 ? 'cuota' : 'cuotas'}');
    } else if (isCard) {
      subtitleParts.add(metricValue);
    }

    final showMarkPaid = isLoan &&
        nextPayment != null &&
        nextPayment!.installment != null &&
        onTogglePaid != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot alineado a la primera línea de texto
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bankColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Línea 1: nombre + badge de urgencia
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          credit.name,
                          style: const TextStyle(
                            fontSize: AppTextSize.body,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (urgencyLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: urgencyColor!.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            urgencyLabel,
                            style: TextStyle(
                              fontSize: AppTextSize.caption,
                              fontWeight: FontWeight.w700,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Línea 2: subtítulo + acción
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          subtitleParts.join(' · '),
                          style: TextStyle(
                            fontSize: AppTextSize.body,
                            color: kredit.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                              ),
                              child: Text(
                                paid ? 'Pagado' : 'Marcar pago',
                                style: TextStyle(
                                  fontSize: AppTextSize.body,
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
          ],
        ),
      ),
    );
  }
}

/// Lista de créditos ordenada por urgencia — vive dentro del coach card.
/// [priorityCreditId]: ID del crédito ya mostrado en "Siguiente compromiso";
/// se excluye de esta lista para evitar duplicados.
class _CreditsListSection extends ConsumerWidget {
  final List<Credit> credits;
  final List<PendingPayment> upcoming;
  final String? priorityCreditId;

  const _CreditsListSection({
    required this.credits,
    required this.upcoming,
    this.priorityCreditId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;

    final displayCredits = priorityCreditId == null
        ? credits
        : credits.where((c) => c.id != priorityCreditId).toList();

    if (displayCredits.isEmpty) return const SizedBox.shrink();

    PendingPayment? nextFor(Credit c) =>
        upcoming.where((p) => p.credit.id == c.id).firstOrNull;

    final sorted = [...displayCredits]..sort((a, b) {
      final pa = nextFor(a);
      final pb = nextFor(b);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pa.daysUntilDue().compareTo(pb.daysUntilDue());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: kredit.borderCard),
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
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: AppIconSize.large,
              color: kredit.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes créditos registrados',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTextSize.body,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera tarjeta o préstamo para empezar a llevar el control.',
              style: TextStyle(
                fontSize: AppTextSize.body,
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

