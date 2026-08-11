/// Mirrors a movement entry of a card's `movements[]` array in app.js
/// (registerCardMovement ~L763, accrueCardCredit ~L703).
library;

/// Movement kinds, matching the JS string literals exactly.
class CardMovementType {
  static const charge = 'charge';
  static const payment = 'payment';
  static const interest = 'interest';
  static const fee = 'fee';
}

class CardMovement {
  /// "YYYY-MM-DD"
  final String date;

  /// One of [CardMovementType].
  final String type;

  final double amount;
  final String note;

  const CardMovement({
    required this.date,
    required this.type,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'type': type,
        'amount': amount,
        'note': note,
      };

  factory CardMovement.fromJson(Map<String, dynamic> json) => CardMovement(
        date: json['date'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
      );
}
