/// Mirrors a movement entry of a card's `movements[]` array in app.js
/// (registerCardMovement ~L763, accrueCardCredit ~L703).
library;

/// Movement kinds, matching the JS string literals exactly.
class CardMovementType {
  static const charge = 'charge';
  static const payment = 'payment';
  static const interest = 'interest';
  static const fee = 'fee';
  static const advance = 'advance';
}

class CardMovement {
  /// "YYYY-MM-DD"
  final String date;

  /// One of [CardMovementType].
  final String type;

  final double amount;
  final String note;

  final int? advanceInstallments;
  final double? advanceInterestRate;
  final String? advanceInterestRateType;
  final double? advanceCommission;
  final String? advanceFirstPaymentDate;
  final String? advanceDestination;

  /// Categoría del movimiento — null para movimientos sin categorizar.
  /// Valores sugeridos: 'alimentacion' | 'transporte' | 'salud' | 'ropa' |
  /// 'entretenimiento' | 'servicios' | 'viajes' | 'otro'.
  final String? categoria;

  /// Para charges: número de cuotas (null = pago único / rotativo)
  final int? chargeInstallments;
  /// Para charges: tasa mensual override (null = usar la de la tarjeta)
  final double? chargeMonthlyRate;

  CardMovement({
    required this.date,
    required this.type,
    required this.amount,
    this.note = '',
    this.advanceInstallments,
    this.advanceInterestRate,
    this.advanceInterestRateType,
    this.advanceCommission,
    this.advanceFirstPaymentDate,
    this.advanceDestination,
    this.categoria,
    this.chargeInstallments,
    this.chargeMonthlyRate,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'type': type,
        'amount': amount,
        'note': note,
        'advanceInstallments': advanceInstallments,
        'advanceInterestRate': advanceInterestRate,
        'advanceInterestRateType': advanceInterestRateType,
        'advanceCommission': advanceCommission,
        'advanceFirstPaymentDate': advanceFirstPaymentDate,
        'advanceDestination': advanceDestination,
        'categoria': categoria,
        'chargeInstallments': chargeInstallments,
        'chargeMonthlyRate': chargeMonthlyRate,
      };

  factory CardMovement.fromJson(Map<String, dynamic> json) => CardMovement(
        date: json['date'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        advanceInstallments: json['advanceInstallments'] as int?,
        advanceInterestRate: (json['advanceInterestRate'] as num?)?.toDouble(),
        advanceInterestRateType: json['advanceInterestRateType'] as String?,
        advanceCommission: (json['advanceCommission'] as num?)?.toDouble(),
        advanceFirstPaymentDate: json['advanceFirstPaymentDate'] as String?,
        advanceDestination: json['advanceDestination'] as String?,
        categoria: json['categoria'] as String?,
        chargeInstallments: json['chargeInstallments'] as int?,
        chargeMonthlyRate: (json['chargeMonthlyRate'] as num?)?.toDouble(),
      );
}
