import '../../domain/interest_rate.dart';
import 'card_movement.dart';
import 'installment.dart';
import 'loan_abono.dart';

/// `type` discriminator values, matching app.js string literals exactly.
class CreditType {
  static const loan = 'loan';
  static const card = 'card';
}

/// Frequency values for loan/cupo credits, matching app.js string literals.
class CreditFrequency {
  static const weekly = 'weekly';
  static const biweekly = 'biweekly';
  static const monthly = 'monthly';
}

/// Management fee frequency for cards.
class ManagementFeeFrequency {
  static const monthly = 'monthly';
  static const annual = 'annual';
}

/// Common fields shared by both credit kinds (fields present on every entry
/// of `state.credits` in app.js, regardless of `type`).
abstract class Credit {
  final String id;
  final String type; // CreditType.loan | CreditType.card
  String name;
  String lender;
  String? color;
  String? notes;

  Credit({
    required this.id,
    required this.type,
    required this.name,
    required this.lender,
    this.color,
    this.notes,
  });

  bool get isCard => type == CreditType.card;
  bool get isLoan => type == CreditType.loan;
}

/// "Cupo/Préstamo" (fixed-installment) credit.
class LoanCredit extends Credit {
  String? location;
  String? card;
  double totalAmount;
  double quotaAmount;
  int totalInstallments;
  String frequency; // CreditFrequency.*
  String startDate; // "YYYY-MM-DD"
  double interestRate;

  /// How `interestRate` is expressed (effectiveAnnual|effectiveMonthly|
  /// nominalMonthly), same enum as CardCredit.interestRateType — see
  /// `interest_rate.dart`. Defaults to E.A. to match the historical
  /// (pre-French-amortization) assumption for existing data.
  String interestRateType;

  List<Installment> installments;
  List<LoanAbono> abonos;

  LoanCredit({
    required super.id,
    required super.name,
    required super.lender,
    super.color,
    super.notes,
    this.location,
    this.card,
    required this.totalAmount,
    required this.quotaAmount,
    required this.totalInstallments,
    required this.frequency,
    required this.startDate,
    this.interestRate = 0,
    this.interestRateType = InterestRateType.effectiveAnnual,
    List<Installment>? installments,
    List<LoanAbono>? abonos,
  })  : installments = installments ?? [],
        abonos = abonos ?? [],
        super(type: CreditType.loan);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'lender': lender,
        'location': location,
        'card': card,
        'totalAmount': totalAmount,
        'quotaAmount': quotaAmount,
        'totalInstallments': totalInstallments,
        'frequency': frequency,
        'startDate': startDate,
        'interestRate': interestRate,
        'interestRateType': interestRateType,
        'color': color,
        'notes': notes,
        'installments': installments.map((i) => i.toJson()).toList(),
        'abonos': abonos.map((a) => a.toJson()).toList(),
      };

  factory LoanCredit.fromJson(Map<String, dynamic> json) => LoanCredit(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        lender: json['lender'] as String? ?? '',
        location: json['location'] as String?,
        card: json['card'] as String?,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        quotaAmount: (json['quotaAmount'] as num?)?.toDouble() ?? 0,
        totalInstallments: (json['totalInstallments'] as num?)?.toInt() ?? 0,
        frequency: json['frequency'] as String? ?? CreditFrequency.monthly,
        startDate: json['startDate'] as String,
        interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
        interestRateType: json['interestRateType'] as String? ??
            InterestRateType.effectiveAnnual,
        color: json['color'] as String?,
        notes: json['notes'] as String?,
        installments: (json['installments'] as List<dynamic>? ?? [])
            .map((e) => Installment.fromJson(e as Map<String, dynamic>))
            .toList(),
        abonos: (json['abonos'] as List<dynamic>? ?? [])
            .map((e) => LoanAbono.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Revolving credit card credit.
class CardCredit extends Credit {
  double creditLimit;
  double currentBalance;
  int cutoffDay;
  int paymentDueOffsetDays;
  double interestRate;
  String interestRateType; // InterestRateType.*
  double managementFee;
  String managementFeeFrequency; // ManagementFeeFrequency.*
  int cycleCount;

  /// "YYYY-MM-DD" of the last cutoff interest/fees were accrued up to, or
  /// null if never accrued yet.
  String? lastAccrualCutoff;

  List<CardMovement> movements;

  CardCredit({
    required super.id,
    required super.name,
    required super.lender,
    super.color,
    super.notes,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.cutoffDay = 1,
    this.paymentDueOffsetDays = 20,
    this.interestRate = 0,
    this.interestRateType = InterestRateType.effectiveAnnual,
    this.managementFee = 0,
    this.managementFeeFrequency = ManagementFeeFrequency.monthly,
    this.cycleCount = 0,
    this.lastAccrualCutoff,
    List<CardMovement>? movements,
  })  : movements = movements ?? [],
        super(type: CreditType.card);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'lender': lender,
        'color': color,
        'notes': notes,
        'creditLimit': creditLimit,
        'currentBalance': currentBalance,
        'cutoffDay': cutoffDay,
        'paymentDueOffsetDays': paymentDueOffsetDays,
        'interestRate': interestRate,
        'interestRateType': interestRateType,
        'managementFee': managementFee,
        'managementFeeFrequency': managementFeeFrequency,
        'cycleCount': cycleCount,
        'lastAccrualCutoff': lastAccrualCutoff,
        'movements': movements.map((m) => m.toJson()).toList(),
      };

  factory CardCredit.fromJson(Map<String, dynamic> json) => CardCredit(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        lender: json['lender'] as String? ?? '',
        color: json['color'] as String?,
        notes: json['notes'] as String?,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
        cutoffDay: (json['cutoffDay'] as num?)?.toInt() ?? 1,
        paymentDueOffsetDays:
            (json['paymentDueOffsetDays'] as num?)?.toInt() ?? 20,
        interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
        interestRateType: json['interestRateType'] as String? ??
            InterestRateType.effectiveAnnual,
        managementFee: (json['managementFee'] as num?)?.toDouble() ?? 0,
        managementFeeFrequency: json['managementFeeFrequency'] as String? ??
            ManagementFeeFrequency.monthly,
        cycleCount: (json['cycleCount'] as num?)?.toInt() ?? 0,
        lastAccrualCutoff: json['lastAccrualCutoff'] as String?,
        movements: (json['movements'] as List<dynamic>? ?? [])
            .map((e) => CardMovement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Parses a single credit JSON entry into the right subtype based on `type`,
/// mirroring how app.js keeps both shapes in one flat `state.credits` array.
Credit creditFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? CreditType.loan;
  return type == CreditType.card
      ? CardCredit.fromJson(json)
      : LoanCredit.fromJson(json);
}
