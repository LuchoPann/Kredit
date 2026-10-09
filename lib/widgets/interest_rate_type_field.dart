import 'package:flutter/material.dart';

import '../domain/interest_rate.dart';
import '../theme/app_theme.dart';

/// Shared "¿Cómo está expresada tu tasa?" dropdown (E.A. / E.M. / mensual
/// simple), used by both the card and loan sections of add/edit credit
/// sheets so the periodicity selector looks and behaves identically
/// wherever an interest rate is entered — see `interest_rate.dart` for the
/// normalization this feeds into.
class InterestRateTypeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const InterestRateTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    // Mismo fontSize explícito que el campo de texto vecino (ej. "Interés
    // anual (%)") — sin esto, este dropdown cae al estilo por defecto de
    // Material (distinto tamaño/peso) y ambos campos de la misma fila se
    // ven visiblemente descuadrados entre sí, aunque compartan isDense.
    const style = TextStyle(fontSize: AppTextSize.body);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      style: style.copyWith(color: kredit.textPrimary),
      initialValue: value,
      decoration: const InputDecoration(labelText: '¿Cómo está expresada tu tasa?'),
      items: const [
        DropdownMenuItem(
          value: InterestRateType.effectiveAnnual,
          child: Text('Efectiva Anual (E.A.)', style: style),
        ),
        DropdownMenuItem(
          value: InterestRateType.effectiveMonthly,
          child: Text('Efectiva Mensual (E.M.)', style: style),
        ),
        DropdownMenuItem(
          value: InterestRateType.nominalMonthly,
          child: Text('Mensual simple (sin capitalizar)', style: style),
        ),
      ],
      onChanged: (v) => onChanged(v ?? InterestRateType.effectiveAnnual),
    );
  }
}
