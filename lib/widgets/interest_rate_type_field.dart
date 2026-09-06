import 'package:flutter/material.dart';

import '../domain/interest_rate.dart';

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
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: '¿Cómo está expresada tu tasa?'),
      items: const [
        DropdownMenuItem(
          value: InterestRateType.effectiveAnnual,
          child: Text('Efectiva Anual (E.A.)'),
        ),
        DropdownMenuItem(
          value: InterestRateType.effectiveMonthly,
          child: Text('Efectiva Mensual (E.M.)'),
        ),
        DropdownMenuItem(
          value: InterestRateType.nominalMonthly,
          child: Text('Mensual simple (sin capitalizar)'),
        ),
      ],
      onChanged: (v) => onChanged(v ?? InterestRateType.effectiveAnnual),
    );
  }
}
