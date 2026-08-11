import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/wallet_card.dart';

const List<String> _presetLenders = [
  'Bancolombia',
  'Nequi',
  'Nu (Nubank)',
  'Davivienda',
  'DaviPlata',
  'BBVA',
  'RappiCard',
  'Lulo Bank',
  'Banco de Bogotá',
  'Banco Falabella',
  'Scotiabank Colpatria',
  'Banco Popular',
  'Banco AV Villas',
  'Banco de Occidente',
  'Itaú',
  'Tarjeta Tuya / Éxito',
  'Otro...',
];

const List<String> _presetLocations = [
  'Ninguno / Prestamista',
  'Almacenes Éxito',
  'Alkosto / Ktronix',
  'Falabella',
  'Mercado Libre',
  'Amazon',
  'Jumbo / Metro',
  'Olímpica',
  'Apple Store',
  'Samsung Store',
  'Claro / Movistar',
  'Otro...',
];

const List<String> _presetCards = [
  'Cuenta Débito Bancolombia',
  'Nequi',
  'DaviPlata',
  'RappiCuenta / Débito',
  'Lulo Bank',
  'Cuenta de Ahorros',
  'Efectivo',
  'Otra...',
];

/// Applies the same re-proration algorithm as app.js's updateCreditData
/// (~L582-600): when the quota amount changes, only the NOT-yet-paid
/// installments are re-split into principal/interest so the new quota adds
/// up against the remaining principal still owed.
void reprorateUnpaidInstallments(LoanCredit credit, double newQuota) {
  if (newQuota == credit.quotaAmount) return;

  final unpaid = credit.installments.where((i) => !i.paid).toList();
  final unpaidCount = unpaid.length;
  final paidPrincipal = credit.installments
      .where((i) => i.paid)
      .fold(0.0, (s, i) => s + i.principal);
  final remainingPrincipalOwed = math.max(0.0, credit.totalAmount - paidPrincipal);

  credit.quotaAmount = newQuota;
  final totalInterestRemaining =
      math.max(0.0, (newQuota * unpaidCount) - remainingPrincipalOwed);
  final interestPerRemaining = unpaidCount > 0 ? totalInterestRemaining / unpaidCount : 0.0;
  final principalPerRemaining = newQuota - interestPerRemaining;

  for (final inst in unpaid) {
    inst.amount = newQuota;
    inst.principal = principalPerRemaining;
    inst.interest = interestPerRemaining;
  }
}

/// "Editar Información del Crédito" form, mirroring #modal-edit-credit in
/// legacy_pwa/index.html (~L650-759) and updateCreditData() in app.js
/// (~L556-611). The credit type cannot be changed here.
class EditCreditSheet extends ConsumerStatefulWidget {
  final Credit credit;

  const EditCreditSheet({super.key, required this.credit});

  static Future<void> show(BuildContext context, Credit credit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditCreditSheet(credit: credit),
    );
  }

  @override
  ConsumerState<EditCreditSheet> createState() => _EditCreditSheetState();
}

class _EditCreditSheetState extends ConsumerState<EditCreditSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _color;
  bool _saving = false;
  late String? _selectedLenderPreset = _presetLenders.contains(widget.credit.lender) ? widget.credit.lender : 'Otro...';
  late String? _selectedLocationPreset = () {
    if (widget.credit is! LoanCredit) return null;
    final loc = (widget.credit as LoanCredit).location ?? '';
    return _presetLocations.contains(loc) ? loc : (loc.isEmpty ? 'Ninguno / Prestamista' : 'Otro...');
  }();
  late String? _selectedCardPreset = () {
    if (widget.credit is! LoanCredit) return null;
    final c = (widget.credit as LoanCredit).card ?? '';
    return _presetCards.contains(c) ? c : (c.isEmpty ? null : 'Otra...');
  }();

  late final _nameCtrl = TextEditingController(text: widget.credit.name);
  late final _lenderCtrl = TextEditingController(text: widget.credit.lender);
  late final _notesCtrl = TextEditingController(text: widget.credit.notes ?? '');

  // Loan
  late final _locationCtrl =
      TextEditingController(text: widget.credit is LoanCredit ? (widget.credit as LoanCredit).location ?? '' : '');
  late final _cardCtrl =
      TextEditingController(text: widget.credit is LoanCredit ? (widget.credit as LoanCredit).card ?? '' : '');
  late final _quotaCtrl = TextEditingController(
      text: widget.credit is LoanCredit ? (widget.credit as LoanCredit).quotaAmount.toString() : '');
  late final _interestCtrl =
      TextEditingController(text: widget.credit.isLoan ? (widget.credit as LoanCredit).interestRate.toString() : '');

  // Card
  late final _limitCtrl = TextEditingController(
      text: widget.credit is CardCredit ? (widget.credit as CardCredit).creditLimit.toString() : '');
  late final _interestCardCtrl = TextEditingController(
      text: widget.credit is CardCredit ? (widget.credit as CardCredit).interestRate.toString() : '');
  late final _cutoffDayCtrl = TextEditingController(
      text: widget.credit is CardCredit ? (widget.credit as CardCredit).cutoffDay.toString() : '');
  late final _paymentOffsetCtrl = TextEditingController(
      text: widget.credit is CardCredit ? (widget.credit as CardCredit).paymentDueOffsetDays.toString() : '');
  late final _managementFeeCtrl = TextEditingController(
      text: widget.credit is CardCredit ? (widget.credit as CardCredit).managementFee.toString() : '');
  late String _managementFeeFrequency =
      widget.credit is CardCredit ? (widget.credit as CardCredit).managementFeeFrequency : ManagementFeeFrequency.monthly;

  @override
  void initState() {
    super.initState();
    _color = widget.credit.color ?? '#00F2FE';
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _lenderCtrl,
      _notesCtrl,
      _locationCtrl,
      _cardCtrl,
      _quotaCtrl,
      _interestCtrl,
      _limitCtrl,
      _interestCardCtrl,
      _cutoffDayCtrl,
      _paymentOffsetCtrl,
      _managementFeeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final credit = widget.credit;
    credit.name = _nameCtrl.text.trim();
    credit.lender = _lenderCtrl.text.trim();
    credit.color = _color;
    credit.notes = _notesCtrl.text.trim();

    if (credit is CardCredit) {
      credit.creditLimit = double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0;
      credit.interestRate = double.tryParse(_interestCardCtrl.text.replaceAll(',', '.')) ?? 0;
      credit.cutoffDay = int.tryParse(_cutoffDayCtrl.text) ?? 1;
      credit.paymentDueOffsetDays = int.tryParse(_paymentOffsetCtrl.text) ?? 20;
      credit.managementFee = double.tryParse(_managementFeeCtrl.text.replaceAll(',', '.')) ?? 0;
      credit.managementFeeFrequency = _managementFeeFrequency;
    } else if (credit is LoanCredit) {
      credit.location = _locationCtrl.text.trim();
      credit.card = _cardCtrl.text.trim();
      credit.interestRate = double.tryParse(_interestCtrl.text.replaceAll(',', '.')) ?? 0;
      final newQuota = double.tryParse(_quotaCtrl.text.replaceAll(',', '.'));
      if (newQuota != null) {
        reprorateUnpaidInstallments(credit, newQuota);
      }
    }

    try {
      await ref.read(creditsProvider.notifier).updateCredit(credit);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crédito actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar los cambios: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCard = widget.credit is CardCredit;
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(KreditSpacing.card),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: kredit.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Editar Información del Crédito', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Live preview of the card as user edits lender/name
                Builder(
                  builder: (context) {
                    final loan = widget.credit is LoanCredit ? widget.credit as LoanCredit : null;
                    final previewCredit = loan != null
                        ? LoanCredit(
                            id: loan.id,
                            name: _nameCtrl.text.isEmpty ? loan.name : _nameCtrl.text,
                            lender: _lenderCtrl.text.isEmpty ? loan.lender : _lenderCtrl.text,
                            totalAmount: loan.totalAmount,
                            quotaAmount: loan.quotaAmount,
                            interestRate: loan.interestRate,
                            totalInstallments: loan.totalInstallments,
                            startDate: loan.startDate,
                            frequency: loan.frequency,
                            color: _color,
                            location: _locationCtrl.text,
                            card: _cardCtrl.text,
                          )
                        : CardCredit(
                            id: widget.credit.id,
                            name: _nameCtrl.text.isEmpty ? widget.credit.name : _nameCtrl.text,
                            lender: _lenderCtrl.text.isEmpty ? widget.credit.lender : _lenderCtrl.text,
                            creditLimit: (widget.credit as CardCredit).creditLimit,
                            cutoffDay: int.tryParse(_cutoffDayCtrl.text) ?? 15,
                            paymentDueOffsetDays: int.tryParse(_paymentOffsetCtrl.text) ?? 20,
                            interestRate: (widget.credit as CardCredit).interestRate,
                            color: _color,
                          );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VISTA PREVIA DE TARJETA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        WalletCard(credit: previewCredit),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Crédito'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: _selectedLenderPreset == 'Otro...' ? 1 : 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLenderPreset,
                        decoration: const InputDecoration(labelText: 'Banco / Prestamista'),
                        items: _presetLenders
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedLenderPreset = v;
                            if (v != null && v != 'Otro...') {
                              _lenderCtrl.text = v;
                              final lower = v.toLowerCase();
                              if (lower.contains('nequi')) {
                                _color = '#DA0081';
                              } else if (lower.contains('nu')) {
                                _color = '#820AD1';
                              } else if (lower.contains('bancolombia')) {
                                _color = '#FFDD00';
                              } else if (lower.contains('davivienda') || lower.contains('daviplata')) {
                                _color = '#E4032E';
                              } else if (lower.contains('bbva')) {
                                _color = '#004481';
                              } else if (lower.contains('rappi')) {
                                _color = '#FE3F23';
                              } else if (lower.contains('lulo')) {
                                _color = '#00E28A';
                              } else if (lower.contains('popular')) {
                                _color = '#00875A';
                              } else if (lower.contains('occidente')) {
                                _color = '#00205B';
                              } else if (lower.contains('villas')) {
                                _color = '#0055A5';
                              } else if (lower.contains('itaú') || lower.contains('itau')) {
                                _color = '#EC7000';
                              } else if (lower.contains('tuya') || lower.contains('exito')) {
                                _color = '#FFD100';
                              }
                            } else if (v == 'Otro...') {
                              _lenderCtrl.clear();
                            }
                          });
                        },
                        validator: (_) => (_lenderCtrl.text.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    if (_selectedLenderPreset == 'Otro...') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _lenderCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Escribir libre',
                            hintText: 'Ej. PrestaYa...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: kredit.borderCard),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.request_quote_outlined, size: 14, color: kredit.textTertiary),
                    const SizedBox(width: 6),
                    const Text('Datos Financieros', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isCard) ...[
                  _EditSectionCard(
                    label: 'DÓNDE Y CON QUÉ',
                    icon: Icons.storefront_outlined,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedLocationPreset,
                                  decoration: const InputDecoration(labelText: 'Comercio / Establecimiento'),
                                  items: _presetLocations
                                      .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedLocationPreset = v;
                                      if (v != null && v != 'Otro...') {
                                        _locationCtrl.text = v == 'Ninguno / Prestamista' ? '' : v;
                                      } else if (v == 'Otro...') {
                                        _locationCtrl.clear();
                                      }
                                    });
                                  },
                                ),
                                if (_selectedLocationPreset == 'Otro...') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _locationCtrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Escribir libre',
                                      hintText: 'Ej. Tienda de la esquina...',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCardPreset,
                                  decoration: const InputDecoration(labelText: 'Cuenta de Pago / Cargo'),
                                  items: _presetCards
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCardPreset = v;
                                      if (v != null && v != 'Otra...') {
                                        _cardCtrl.text = v;
                                      } else if (v == 'Otra...') {
                                        _cardCtrl.clear();
                                      }
                                    });
                                  },
                                ),
                                if (_selectedCardPreset == 'Otra...') ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cardCtrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Escribir libre',
                                      hintText: 'Ej. Cuenta Banco Popular...',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'MONTO Y CUOTA',
                    icon: Icons.percent_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quotaCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Valor Cuota (\$)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _interestCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Interés anual (%)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  _EditSectionCard(
                    label: 'LÍMITE E INTERÉS',
                    icon: Icons.credit_card_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _limitCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Límite Total (\$)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _interestCardCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Interés anual (%)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'CORTE Y FECHA DE PAGO',
                    icon: Icons.event_available_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: int.tryParse(_cutoffDayCtrl.text) ?? 15,
                              decoration: const InputDecoration(labelText: 'Día de Corte'),
                              items: List.generate(31, (i) => i + 1)
                                  .map((d) => DropdownMenuItem(value: d, child: Text('Día $d de cada mes')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _cutoffDayCtrl.text = v.toString());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: int.tryParse(_paymentOffsetCtrl.text) ?? 20,
                              decoration: const InputDecoration(labelText: 'Días Hasta Fecha Límite'),
                              items: [10, 15, 20, 25, 30, 35, 40]
                                  .map((d) => DropdownMenuItem(value: d, child: Text('$d días después del corte')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _paymentOffsetCtrl.text = v.toString());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditSectionCard(
                    label: 'MANTENIMIENTO',
                    icon: Icons.request_quote_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _managementFeeCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Cuota de Mantenimiento (\$)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _managementFeeFrequency,
                              decoration: const InputDecoration(labelText: 'Frecuencia de Cobro'),
                              items: const [
                                DropdownMenuItem(value: ManagementFeeFrequency.monthly, child: Text('Mensual')),
                                DropdownMenuItem(value: ManagementFeeFrequency.annual, child: Text('Anual')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _managementFeeFrequency = v ?? ManagementFeeFrequency.monthly),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Divider(color: kredit.borderCard),
                const SizedBox(height: 12),
                const Text('Color de Tarjeta / Identificador', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: AppColors.accentOptions.map((c) {
                    final hex = '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                    final selected = hex.toUpperCase() == _color.toUpperCase();
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? kredit.textPrimary : kredit.borderCard,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Indicaciones / Comentarios'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar Cambios'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Boxed section grouping a related cluster of fields (e.g. "monto/cuota"
/// vs. "corte/fecha de pago") — same visual language as add_credit_sheet's
/// step-2 grouping, so add/edit read as one consistent form system.
class _EditSectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _EditSectionCard({required this.label, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.tile),
      decoration: BoxDecoration(
        color: kredit.bgSecondary,
        border: Border.all(color: kredit.borderCard),
        borderRadius: BorderRadius.circular(KreditRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kredit.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: kredit.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
