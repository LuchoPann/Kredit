import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../data/models/pago_realizado.dart';
import '../../domain/date_utils.dart';
import '../../providers/database_provider.dart';
import '../../providers/pagos_realizados_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import 'registrar_pago_sheet.dart';

class PagosTab extends ConsumerWidget {
  final LoanCredit credit;

  const PagosTab({super.key, required this.credit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosRealizadosProvider(credit.id));

    return pagosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (pagos) => _PagosBody(credit: credit, pagos: pagos),
    );
  }
}

class _PagosBody extends ConsumerWidget {
  final LoanCredit credit;
  final List<PagoRealizado> pagos;

  const _PagosBody({required this.credit, required this.pagos});

  List<_CuotaMora> _cuotasMorasSinRegistro() {
    final now = DateTime.now();
    final registradas = pagos.map((p) => p.numeroCuota).toSet();
    return credit.installments
        .where((inst) =>
            !inst.paid &&
            !registradas.contains(inst.number) &&
            parseDateStr(inst.dueDate).isBefore(now))
        .map((inst) {
          final diasMora = now.difference(parseDateStr(inst.dueDate)).inDays;
          return _CuotaMora(inst: inst, diasMora: diasMora);
        })
        .toList()
      ..sort((a, b) => a.inst.number.compareTo(b.inst.number));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final mora = _cuotasMorasSinRegistro();
    final hayContenido = pagos.isNotEmpty || mora.isNotEmpty;

    if (!hayContenido) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: KreditIconSize.large, color: kredit.success),
            const SizedBox(height: 12),
            Text(
              'Todos los pagos al día.',
              style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.heading),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [
        if (mora.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            label: 'Cuotas vencidas sin registrar',
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          ...mora.map((m) => _MoraItem(credit: credit, cuota: m)),
          const SizedBox(height: 20),
        ],
        if (pagos.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.history,
            label: 'Pagos registrados',
            color: kredit.textSecondary,
          ),
          const SizedBox(height: 8),
          ...pagos.map((p) => _PagoItem(pago: p, credit: credit, ref: ref)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: KreditIconSize.small, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: KreditTextSize.body,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MoraItem extends StatelessWidget {
  final LoanCredit credit;
  final _CuotaMora cuota;

  const _MoraItem({required this.credit, required this.cuota});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final inst = cuota.inst;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuota #${inst.number} — ${formatCOP(inst.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kredit.textPrimary,
                    fontSize: KreditTextSize.body,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Venció ${formatDate(inst.dueDate)} · ${cuota.diasMora} días de mora',
                  style: TextStyle(
                    fontSize: KreditTextSize.body,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => RegistrarPagoSheet.show(context, credit, inst),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}

class _PagoItem extends StatelessWidget {
  final PagoRealizado pago;
  final LoanCredit credit;
  final WidgetRef ref;

  const _PagoItem({required this.pago, required this.credit, required this.ref});

  double _montoProyectado() {
    if (pago.numeroCuota == null) return 0;
    final inst = credit.installments
        .where((i) => i.number == pago.numeroCuota)
        .firstOrNull;
    return inst?.amount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final proyectado = _montoProyectado();
    final diff = pago.monto - proyectado;
    final esAhorro = diff <= 0;
    final diffColor = esAhorro ? kredit.success : AppColors.danger;
    final diffLabel = esAhorro
        ? '−${formatCOP(-diff)} ahorro'
        : '+${formatCOP(diff)} sobre lo proyectado';

    return Dismissible(
      key: ValueKey(pago.rowId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(KreditRadius.tile),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar pago'),
            content: const Text('¿Eliminar este registro de pago?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        if (pago.rowId != null) {
          final db = ref.read(databaseProvider);
          await db.deletePagoRealizado(pago.rowId!);
          ref.invalidate(pagosRealizadosProvider(credit.id));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(color: kredit.borderCard.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pago.numeroCuota != null
                        ? 'Cuota #${pago.numeroCuota} — ${formatDate(pago.fecha)}'
                        : 'Pago — ${formatDate(pago.fecha)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kredit.textPrimary,
                      fontSize: KreditTextSize.body,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (proyectado > 0)
                    Text(
                      'Proyectado ${formatCOP(proyectado)} · Real ${formatCOP(pago.monto)}',
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textSecondary,
                      ),
                    ),
                  if (pago.nota.isNotEmpty)
                    Text(
                      pago.nota,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCOP(pago.monto),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kredit.textPrimary,
                    fontSize: KreditTextSize.heading,
                  ),
                ),
                if (proyectado > 0)
                  Text(
                    diffLabel,
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: diffColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CuotaMora {
  final Installment inst;
  final int diasMora;

  _CuotaMora({required this.inst, required this.diasMora});
}
