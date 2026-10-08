part of 'add_credit_sheet.dart';

// ─── Widgets nuevos ─────────────────────────────────────────────────────────

class _SubTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final KreditColors kredit;

  const _SubTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : kredit.bgCard,
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: KreditIconSize.medium, color: selected ? accent : kredit.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final KreditColors kredit;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kredit.borderCard),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: KreditIconSize.medium),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: KreditTextSize.heading, fontWeight: FontWeight.w700, color: kredit.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kredit.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _BankChipPicker extends StatelessWidget {
  final List<String> banks;
  final String? selectedBank;
  final ValueChanged<String> onSelected;
  final KreditColors kredit;

  const _BankChipPicker({
    required this.banks,
    required this.selectedBank,
    required this.onSelected,
    required this.kredit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: banks.map((bank) {
        final selected = selectedBank == bank;
        return FilterChip(
          label: Text(bank),
          selected: selected,
          onSelected: (_) => onSelected(bank),
          selectedColor: accent.withValues(alpha: 0.15),
          checkmarkColor: accent,
          labelStyle: TextStyle(
            color: selected ? accent : kredit.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class _InterestUnknownRow extends StatelessWidget {
  final bool interestUnknown;
  final ValueChanged<bool> onChanged;
  const _InterestUnknownRow({required this.interestUnknown, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: interestUnknown,
      onChanged: onChanged,
      title: Text('Tasa desconocida', style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
      subtitle: Text('Kredit no mostrará tasa ni calculará intereses.', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
    );
  }
}

class _EarlyPaymentRow extends StatelessWidget {
  final bool earlyPaymentWaivesInterest;
  final ValueChanged<bool> onChanged;
  const _EarlyPaymentRow({required this.earlyPaymentWaivesInterest, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: earlyPaymentWaivesInterest,
      onChanged: onChanged,
      title: Text('Pago anticipado sin interés', style: TextStyle(fontWeight: FontWeight.w600, color: kredit.textPrimary)),
      subtitle: Text('Actívalo si la entidad condona el interés al pagar antes del vencimiento.', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textSecondary)),
    );
  }
}

/// Non-blocking hint shown under the interest rate field when the entered
/// value looks like it might be mismatched (monthly vs. E.A.), with the
/// same small warning-icon-plus-text treatment used for the Nequi/DaviPlata
/// type suggestion. when the entered
/// value looks like it might be mismatched (monthly vs. E.A.), with the
/// same small warning-icon-plus-text treatment used for the Nequi/DaviPlata
/// type suggestion.
class _InterestRateWarningHint extends StatelessWidget {
  final String text;
  const _InterestRateWarningHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: KreditIconSize.small, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel editorial que reacciona en vivo a lo que el usuario va tecleando en
/// el paso 2 — mismo lenguaje visual que el "DEUDA TOTAL" del dashboard
/// (cifra protagonista en `KreditTextSize.hero`, eyebrow en mayúsculas), en
/// vez de que el paso se sienta solo como una fila de campos rellenables.
/// Para préstamo muestra el valor de cuota ya calculado; para tarjeta,
/// el cupo disponible resultante de límite menos saldo actual.
class _LiveFinancialHero extends StatelessWidget {
  final String type;
  final String quotaText;
  final String limitText;
  final String balanceText;

  const _LiveFinancialHero({
    required this.type,
    required this.quotaText,
    required this.limitText,
    required this.balanceText,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    if (type == CreditType.card) {
      final limit = double.tryParse(CurrencyInputFormatter.unformat(limitText)) ?? 0;
      final balance = double.tryParse(CurrencyInputFormatter.unformat(balanceText)) ?? 0;
      final hasLimit = limit > 0;
      final available = hasLimit ? (limit - balance).clamp(0, limit) : 0.0;
      final usage = hasLimit ? (balance / limit).clamp(0.0, 1.0) : 0.0;
      final usageColor = usage >= 0.85 ? kredit.danger : (usage >= 0.65 ? kredit.warning : accent);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KreditSpacing.card),
        decoration: BoxDecoration(
          color: kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.card),
          border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CUPO DISPONIBLE',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: kredit.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasLimit ? formatCOP(available.toDouble()) : '—',
              style: const TextStyle(
                fontSize: KreditTextSize.hero,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: hasLimit ? usage : 0,
                minHeight: 5,
                backgroundColor: kredit.borderCard.withValues(alpha: 0.55),
                valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasLimit
                  ? 'Usas ${(usage * 100).round()}% de tu cupo de ${formatCOP(limit)}'
                  : 'Ingresa el límite para ver tu cupo disponible',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ),
      );
    }

    final quota = double.tryParse(CurrencyInputFormatter.unformat(quotaText)) ?? 0;
    final hasQuota = quota > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VALOR DE LA CUOTA',
            style: TextStyle(
              fontSize: KreditTextSize.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: kredit.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuota ? formatCOP(quota) : '—',
            style: const TextStyle(
              fontSize: KreditTextSize.hero,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuota
                ? 'Valor aproximado, calculado con base en el monto, las cuotas y el interés ingresados.'
                : 'Completa los datos de abajo para calcularla automáticamente.',
            style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _CreditTypePicker extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _CreditTypePicker({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CreditTypeOption(
          selected: selectedType == CreditType.loan,
          icon: Icons.payments_outlined,
          title: 'Préstamo / Cupo en cuotas',
          subtitle: 'Pagas cuotas fijas y existe una fecha estimada de finalización.',
          onTap: () => onChanged(CreditType.loan),
        ),
        const SizedBox(height: 10),
        _CreditTypeOption(
          selected: selectedType == CreditType.card,
          icon: Icons.credit_card_outlined,
          title: 'Tarjeta de crédito',
          subtitle: 'Maneja saldo rotativo, fecha de corte, fecha límite y cupo disponible.',
          onTap: () => onChanged(CreditType.card),
        ),
      ],
    );
  }
}

class _CreditTypeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreditTypeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : kredit.bgCard,
      borderRadius: BorderRadius.circular(KreditRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        child: Container(
          padding: const EdgeInsets.all(KreditSpacing.card),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KreditRadius.card),
            border: Border.all(
              color: selected ? accent : kredit.borderCard,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.16) : kredit.bgSecondary,
                  borderRadius: BorderRadius.circular(KreditRadius.tile),
                ),
                child: Icon(icon, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        fontWeight: FontWeight.w800,
                        color: kredit.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: KreditTextSize.body,
                        color: kredit.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: KreditIconSize.small,
                color: selected ? accent : kredit.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered step indicator for the 3-step form (Tarea 1): a circle per step
/// (filled = done, outlined-accent = current, dim = upcoming) joined by
/// connector lines, plus the current step's title underneath — clearer than
/// a plain progress bar about *which* step you're on vs. how many remain.
/// Barra de progreso animada. Cuando el número de pasos cambia de 1 → N, los
/// puntos adicionales "ruedan" hacia la derecha revelándose uno a uno desde
// ══════════════════════════════════════════════════════════════════════════════
// Step progress header — sequential fill animations
//
// _InitialStepIndicator (mode == null):
//   1. Dot "0" fills with accent left→right (300ms)
//   2. Future-line expands left→right (220ms)
//   3. Chevrons march →→→ (repeat 1100ms)
//
// _StepProgress (mode != null):
//   _fill: continuous float where dot[i] fills at [2i..2i+1], line[i→i+1] fills
//   at [2i+1..2i+2]. Advancing: line fills L→R then dot fills. Retreating: dot
//   unfills then line shrinks R→L (widthFactor going 1→0 with Alignment.centerLeft).
//   Duration 420ms matches view AnimatedSwitcher so both feel synchronized.
// ══════════════════════════════════════════════════════════════════════════════

class _InitialStepIndicator extends StatefulWidget {
  final KreditColors kredit;
  const _InitialStepIndicator({required this.kredit});

  @override
  State<_InitialStepIndicator> createState() => _InitialStepIndicatorState();
}

class _InitialStepIndicatorState extends State<_InitialStepIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  late final AnimationController _lineCtrl;
  late final AnimationController _arrowCtrl;
  late final Animation<double> _dotAnim;
  late final Animation<double> _lineAnim;
  late final List<Animation<double>> _chevronAnims;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _arrowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _dotAnim = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeOutCubic);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOutCubic);
    _chevronAnims = List.generate(3, (i) {
      final start = i / 3.0;
      final end = (i + 1) / 3.0;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.08).chain(CurveTween(curve: Curves.easeIn)),
          weight: 60,
        ),
      ]).animate(CurvedAnimation(parent: _arrowCtrl, curve: Interval(start, end)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _dotCtrl.forward();
      if (!mounted) return;
      await _lineCtrl.forward();
      if (!mounted) return;
      _arrowCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _lineCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = widget.kredit;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Dot "0" fills with accent color
          AnimatedBuilder(
            animation: _dotAnim,
            builder: (context, _) => Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(kredit.bgSecondary, accent, _dotAnim.value),
                border: Border.all(
                  color: Color.lerp(kredit.borderCard, accent, _dotAnim.value)!,
                  width: 1.5,
                ),
              ),
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(kredit.textTertiary, scaffoldBg, _dotAnim.value),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Line fills left→right — static Container passed as child so
          // AnimatedBuilder only rebuilds the Align wrapper, not the fill.
          Expanded(
            child: AnimatedBuilder(
              animation: _lineAnim,
              child: Container(height: 1.5, color: kredit.borderCard),
              builder: (context, child) => Align(
                alignment: Alignment.centerLeft,
                widthFactor: _lineAnim.value,
                child: child,
              ),
            ),
          ),
          // Chevrons: FadeTransition is layer-based (no widget rebuild per
          // frame) and the icons are pre-built once as the static child tree.
          FadeTransition(
            opacity: _lineAnim,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => FadeTransition(
                  opacity: _chevronAnims[i],
                  child: Icon(Icons.chevron_right_rounded, size: KreditIconSize.medium, color: accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatefulWidget {
  final int currentStep;
  final List<String> titles;
  final KreditColors kredit;

  const _StepProgress({
    required this.currentStep,
    required this.titles,
    required this.kredit,
  });

  @override
  State<_StepProgress> createState() => _StepProgressState();
}

class _StepProgressState extends State<_StepProgress>
    with TickerProviderStateMixin {
  // _fill: dot[i] fills at [2i..2i+1], line[i→i+1] fills at [2i+1..2i+2]
  late final AnimationController _fillCtrl;
  late final Animation<double> _fillCurved;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandCurved;
  late List<String> _displayTitles;

  double _fillFrom = 0.0;
  double _fillTo = 0.0;

  double get _fill =>
      _fillFrom + (_fillTo - _fillFrom) * _fillCurved.value;

  double _dotFill(int i) => (_fill - 2 * i).clamp(0.0, 1.0);
  double _lineFill(int i) => (_fill - (2 * i + 1)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _displayTitles = widget.titles;
    _fillFrom = 0.0;
    _fillTo = (2 * widget.currentStep + 1).toDouble();

    _fillCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fillCurved =
        CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOutCubic);

    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _expandCurved =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fillCtrl.forward();
      if (widget.titles.length > 1) _expandCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_StepProgress old) {
    super.didUpdateWidget(old);

    if (old.currentStep != widget.currentStep) {
      _fillFrom = _fill;
      _fillTo = (2 * widget.currentStep + 1).toDouble();
      _fillCtrl.forward(from: 0);
    }

    if (old.titles.length != widget.titles.length) {
      if (widget.titles.length > old.titles.length) {
        setState(() => _displayTitles = widget.titles);
        _expandCtrl.forward(from: 0);
      } else {
        _expandCtrl.reverse().whenComplete(() {
          if (mounted) setState(() => _displayTitles = widget.titles);
        });
      }
    } else if (_displayTitles != widget.titles) {
      setState(() => _displayTitles = widget.titles);
    }
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  Widget _buildDot(BuildContext context, int step, Color accent) {
    final fill = _dotFill(step);
    final done = step < widget.currentStep;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final kredit = widget.kredit;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(kredit.bgSecondary, accent, fill),
        border: Border.all(
          color: Color.lerp(kredit.borderCard, accent, fill)!,
          width: 1.5,
        ),
      ),
      child: done
          ? Icon(Icons.check,
              size: KreditIconSize.small,
              color: Color.lerp(kredit.textTertiary, scaffoldBg, fill))
          : Text(
              '${step + 1}',
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: FontWeight.w700,
                color: Color.lerp(kredit.textTertiary, scaffoldBg, fill),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final kredit = widget.kredit;
    final n = _displayTitles.length;

    // LayoutBuilder wraps AnimatedBuilder so the layout pass only runs when
    // constraints change — not on every animation frame (60 fps).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: n <= 1
          ? Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _fillCtrl,
                builder: (ctx, _) => _buildDot(ctx, 0, accent),
              ),
            )
          : LayoutBuilder(builder: (ctx, constraints) {
              final segments = n - 1;
              // Dot 0 (24px) is outside the Expanded area, so subtract it
              // before distributing the remaining space among connectors and
              // dots 1..n-1. Without this, the inner SizedBox is 24px wider
              // than the Expanded, causing an overflow warning in debug mode.
              final innerW = constraints.maxWidth - 24.0;
              final connW = (innerW - segments * 24.0) / segments.toDouble();
              return AnimatedBuilder(
                animation: Listenable.merge([_fillCtrl, _expandCtrl]),
                builder: (ctx2, _) => Row(
                  children: [
                    _buildDot(ctx2, 0, accent),
                    Expanded(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _expandCurved.value,
                          child: SizedBox(
                            width: innerW,
                            child: Row(
                              children: [
                                for (int i = 1; i < n; i++) ...[
                                  // Connector line: grey base + accent fill L→R
                                  SizedBox(
                                    width: connW,
                                    child: Stack(
                                      children: [
                                        Container(height: 2, color: kredit.borderCard),
                                        FractionallySizedBox(
                                          widthFactor: _lineFill(i - 1),
                                          alignment: Alignment.centerLeft,
                                          child: Container(height: 2, color: accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildDot(ctx2, i, accent),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
    );
  }
}

/// One "label: value" row used inside the step-3 confirmation summary.
/// Tarjeta de resumen del paso 4: dos columnas de datos alineadas a la
/// izquierda (etiqueta arriba, valor abajo) con una línea interna muy tenue
/// que solo marca la separación de columnas — no una tabla de "etiqueta a
/// la izquierda, valor a la derecha" como antes, que se sentía más a
/// formulario que a resumen visual.
class _SummaryGrid extends StatelessWidget {
  final List<({String label, String value})> items;

  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final left = <({String label, String value})>[];
    final right = <({String label, String value})>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? left : right).add(items[i]);
    }

    Widget column(List<({String label, String value})> data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SummaryTile(label: data[i].label, value: data[i].value),
            ],
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: kredit.borderCard.withValues(alpha: 0.4),
          ),
          Expanded(child: column(right)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: KreditTextSize.body,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Tarjeta visual "Sin entidad específica" — diseño de voucher abstracto dashed.
class _NoEntityCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _NoEntityCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.card),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KreditRadius.tile),
                border: Border.all(
                  color: selected ? accent.withValues(alpha: 0.4) : kredit.borderCard,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                color: kredit.bgSecondary,
              ),
              child: Icon(
                Icons.credit_card_off_outlined,
                size: KreditIconSize.small,
                color: selected ? accent : kredit.textTertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin entidad específica',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : kredit.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Registra el crédito sin vincularlo a una entidad.',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.textTertiary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: KreditIconSize.medium,
              color: selected ? accent : kredit.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón CTA centrado para registrar una nueva entidad.
class _AddEntityButton extends StatelessWidget {
  final bool selected;
  final String? entityName; // nombre configurado si ya se confirmó una entidad
  final VoidCallback onTap;

  const _AddEntityButton({
    required this.selected,
    required this.onTap,
    this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final hasEntity = selected && entityName != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KreditRadius.card),
          gradient: selected
              ? LinearGradient(
                  colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : kredit.bgCard,
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : kredit.bgSecondary,
              ),
              child: Icon(
                hasEntity ? Icons.check : Icons.add,
                size: KreditIconSize.small,
                color: selected ? Colors.black : kredit.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasEntity ? entityName! : 'Nueva entidad',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w800,
                      color: selected ? accent : kredit.textPrimary,
                    ),
                  ),
                  Text(
                    hasEntity ? 'Toca para editar' : 'Banco, tienda o app',
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      color: kredit.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: KreditIconSize.micro,
              color: selected ? accent : kredit.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EntityTypePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : kredit.bgSecondary,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(
            color: selected ? accent : kredit.borderCard,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: KreditIconSize.small, color: selected ? accent : kredit.textTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: KreditTextSize.body,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta/voucher visual de una entidad en el picker del paso 0.
/// Usa [EntityCardFace] — mismo visual que WalletCard pero con disponible
/// dentro de la tarjeta, sin deuda restante.
class _EntityPickerCard extends StatelessWidget {
  final CommercialQuota quota;
  final bool selected;
  final List<LoanCredit> allLoans;
  final VoidCallback onTap;

  const _EntityPickerCard({
    required this.quota,
    required this.selected,
    required this.allLoans,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Cara de tarjeta/voucher con disponible dentro.
          EntityCardFace(quota: quota, allLoans: allLoans),
          // Anillo de selección superpuesto.
          if (selected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 2.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // Check en la esquina superior derecha.
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: selected
                  ? Container(
                      key: const ValueKey('check'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.check, size: KreditIconSize.micro, color: Colors.black),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
