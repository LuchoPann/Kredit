import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../utils/currency_input_formatter.dart';

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  int _installments = 12;

  static const _installmentOptions = [3, 6, 12, 18, 24, 36];

  double get _amount =>
      double.tryParse(CurrencyInputFormatter.unformat(_amountCtrl.text)) ?? 0;

  double get _rate => double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _monthlyPayment {
    final p = _amount;
    final n = _installments;
    if (p <= 0) return 0;
    final r = _rate / 100;
    if (r <= 0) return p / n;
    final factor = math.pow(1 + r, n);
    return p * r * factor / (factor - 1);
  }

  double get _totalPayment => _monthlyPayment * _installments;
  double get _totalInterest => (_totalPayment - _amount).clamp(0, double.infinity);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final hasAmount = _amount > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: kredit.bgPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kredit.borderCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: AppIconSize.medium, color: accent),
                  const SizedBox(width: 12),
                  Text(
                    'Calculadora de cuotas',
                    style: TextStyle(
                      fontSize: AppTextSize.heading,
                      fontWeight: FontWeight.w800,
                      color: kredit.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: kredit.borderCard),
            // Scrollable body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Valor
                  Text(
                    'VALOR DEL ARTÍCULO',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      const CurrencyInputFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: AppTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: r'$ ',
                      prefixStyle: TextStyle(
                        fontSize: AppTextSize.heading,
                        fontWeight: FontWeight.w700,
                        color: kredit.textTertiary,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(color: kredit.textTertiary),
                      filled: true,
                      fillColor: kredit.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: kredit.borderCard),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: kredit.borderCard),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cuotas
                  Text(
                    'NÚMERO DE CUOTAS',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _installmentOptions.map((n) {
                        final sel = n == _installments;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _installments = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? accent.withValues(alpha: 0.15) : kredit.bgCard,
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                                border: Border.all(
                                  color: sel ? accent : kredit.borderCard,
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: AppTextSize.body,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? accent : kredit.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tasa
                  Text(
                    'TASA DE INTERÉS MENSUAL (%)',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: kredit.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: AppTextSize.heading,
                      fontWeight: FontWeight.w700,
                      color: kredit.textPrimary,
                    ),
                    decoration: InputDecoration(
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        fontSize: AppTextSize.heading,
                        fontWeight: FontWeight.w700,
                        color: kredit.textTertiary,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: kredit.textTertiary),
                      helperText: 'Ej: 1.5 para 1.5% mensual. Deja en 0 para cuotas sin interés.',
                      helperStyle: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary),
                      filled: true,
                      fillColor: kredit.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: kredit.borderCard),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: kredit.borderCard),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                        borderSide: BorderSide(color: accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Resultados
                  if (hasAmount) ...[
                    _ResultCard(
                      label: 'CUOTA MENSUAL',
                      value: formatCOP(_monthlyPayment),
                      detail: 'Por $_installments meses',
                      kredit: kredit,
                      accent: accent,
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultCard(
                            label: 'TOTAL A PAGAR',
                            value: formatCOP(_totalPayment),
                            detail: 'Capital + intereses',
                            kredit: kredit,
                            accent: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultCard(
                            label: 'INTERESES',
                            value: formatCOP(_totalInterest),
                            detail: _totalPayment > 0
                                ? '${((_totalInterest / _totalPayment) * 100).toStringAsFixed(1)}% del total'
                                : '—',
                            kredit: kredit,
                            accent: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.card),
                      decoration: BoxDecoration(
                        color: kredit.bgCard,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Ingresa el valor del artículo para ver el cálculo.',
                        style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final AppThemeColors kredit;
  final Color accent;
  final bool highlight;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.kredit,
    required this.accent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: highlight ? accent.withValues(alpha: 0.08) : kredit.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: highlight ? accent.withValues(alpha: 0.4) : kredit.borderCard.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTextSize.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: highlight ? accent : kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? AppTextSize.emphasis : AppTextSize.heading,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: kredit.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(fontSize: AppTextSize.body, color: kredit.textTertiary),
          ),
        ],
      ),
    );
  }
}
