import 'package:flutter/material.dart';

import '../../data/models/credit.dart';
import '../../theme/app_theme.dart';

/// Renders the credit's location/payment-card/comments notes.
///
/// When [embedded] is true (used inside `SummaryTab`'s ListView), this
/// renders as a plain Column with no extra ListView/padding, so it lays
/// out inline instead of trying to scroll independently.
class NotesTab extends StatelessWidget {
  final Credit credit;
  final bool embedded;

  const NotesTab({super.key, required this.credit, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final loan = credit is LoanCredit ? credit as LoanCredit : null;
    final hasContent =
        (loan?.location?.isNotEmpty ?? false) ||
        (loan?.card?.isNotEmpty ?? false) ||
        (credit.notes?.isNotEmpty ?? false);

    if (!hasContent) {
      if (embedded) return const SizedBox.shrink();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin notas adicionales para este crédito.',
            style: TextStyle(color: kredit.textSecondary),
          ),
        ),
      );
    }

    final notesContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTAS Y DETALLES',
          style: TextStyle(
            fontSize: KreditTextSize.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: kredit.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        if (loan?.location?.isNotEmpty ?? false)
          _NoteLine(label: 'Establecimiento', value: loan!.location!),
        if (loan?.card?.isNotEmpty ?? false)
          _NoteLine(label: 'Tarjeta/Cuenta de Cargo', value: loan!.card!),
        if (credit.notes?.isNotEmpty ?? false)
          _NoteLine(
            label: 'Indicaciones / Comentarios',
            value: credit.notes!,
          ),
      ],
    );

    if (embedded) return notesContent;

    return ListView(
      padding: const EdgeInsets.all(KreditSpacing.card),
      children: [notesContent],
    );
  }
}

class _NoteLine extends StatelessWidget {
  final String label;
  final String value;

  const _NoteLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: KreditTextSize.label, color: kredit.textSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: kredit.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
