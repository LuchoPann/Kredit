abstract class EntityType {
  static const store = 'store';
  static const bank = 'bank';
  static const app = 'app';
}

/// A credit entity the user operates with — a store quota (Totto, Lili Pink),
/// a bank card entity (Bancolombia, Davivienda), or an app lender (Addi).
/// Credits inside are `LoanCredit` rows tagged via `LoanCredit.quotaId`, or
/// `CardCredit` rows tagged via `CardCredit.quotaId`.
class CommercialQuota {
  final String id;
  String brand;
  double limit;
  String? notes;
  // [VoucherPattern.name] (see widgets/voucher_pattern.dart) chosen for
  // every voucher under THIS quota specifically — never a single
  // app-wide setting. Null falls back to the first pattern in code.
  String? voucherPattern;

  /// Entity classification — see [EntityType] constants.
  String entityType;

  // --- bank / card entity fields ---
  int? cutoffDay;
  int? paymentOffsetDays;
  double? managementFee;
  String? managementFeeFrequency;

  CommercialQuota({
    required this.id,
    required this.brand,
    required this.limit,
    this.notes,
    this.voucherPattern,
    this.entityType = EntityType.store,
    this.cutoffDay,
    this.paymentOffsetDays,
    this.managementFee,
    this.managementFeeFrequency,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'limit': limit,
        'notes': notes,
        'voucherPattern': voucherPattern,
        'entityType': entityType,
        'cutoffDay': cutoffDay,
        'paymentOffsetDays': paymentOffsetDays,
        'managementFee': managementFee,
        'managementFeeFrequency': managementFeeFrequency,
      };

  factory CommercialQuota.fromJson(Map<String, dynamic> json) =>
      CommercialQuota(
        id: json['id'] as String,
        brand: json['brand'] as String,
        limit: (json['limit'] as num).toDouble(),
        notes: json['notes'] as String?,
        voucherPattern: json['voucherPattern'] as String?,
        entityType: json['entityType'] as String? ?? EntityType.store,
        cutoffDay: (json['cutoffDay'] as num?)?.toInt(),
        paymentOffsetDays: (json['paymentOffsetDays'] as num?)?.toInt(),
        managementFee: (json['managementFee'] as num?)?.toDouble(),
        managementFeeFrequency: json['managementFeeFrequency'] as String?,
      );
}
