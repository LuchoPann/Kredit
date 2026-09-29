/// A commercial credit line the user has with a brand/merchant (e.g. Totto,
/// Lili Pink, Éxito CrediCompras). Deliberately does not model the real
/// financial provider behind the brand (Keypago, Tuya, Credifactory) — the
/// user only ever sees the brand. Purchases inside this quota are normal
/// `LoanCredit` rows tagged with this quota's id via `LoanCredit.quotaId`.
class CommercialQuota {
  final String id;
  String brand;
  double limit;
  String? notes;
  // [VoucherPattern.name] (see widgets/voucher_pattern.dart) chosen for
  // every voucher under THIS quota specifically — never a single
  // app-wide setting. Null falls back to the first pattern in code.
  String? voucherPattern;

  CommercialQuota({
    required this.id,
    required this.brand,
    required this.limit,
    this.notes,
    this.voucherPattern,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'limit': limit,
        'notes': notes,
        'voucherPattern': voucherPattern,
      };

  factory CommercialQuota.fromJson(Map<String, dynamic> json) =>
      CommercialQuota(
        id: json['id'] as String,
        brand: json['brand'] as String,
        limit: (json['limit'] as num).toDouble(),
        notes: json['notes'] as String?,
        voucherPattern: json['voucherPattern'] as String?,
      );
}
