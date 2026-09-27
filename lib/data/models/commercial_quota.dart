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

  CommercialQuota({
    required this.id,
    required this.brand,
    required this.limit,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'limit': limit,
        'notes': notes,
      };

  factory CommercialQuota.fromJson(Map<String, dynamic> json) =>
      CommercialQuota(
        id: json['id'] as String,
        brand: json['brand'] as String,
        limit: (json['limit'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}
