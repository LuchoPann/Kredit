/// Mirrors an installment entry of a loan/cupo's `installments[]` array in
/// app.js (see buildLoanInstallments ~L388 and generateDemoInstallments).
class Installment {
  final int number;

  /// "YYYY-MM-DD"
  final String dueDate;

  /// Amount actually owed for this installment. Equal to principal+interest
  /// unless interestWaived, in which case it equals principal only.
  double amount;

  double principal;
  double interest;
  bool paid;

  /// ISO datetime string (paymentDate), or null if unpaid.
  String? paymentDate;

  bool interestWaived;

  Installment({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.principal,
    required this.interest,
    this.paid = false,
    this.paymentDate,
    this.interestWaived = false,
  });

  Installment copyWith({
    int? number,
    String? dueDate,
    double? amount,
    double? principal,
    double? interest,
    bool? paid,
    String? paymentDate,
    bool? interestWaived,
    bool clearPaymentDate = false,
  }) {
    return Installment(
      number: number ?? this.number,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      paid: paid ?? this.paid,
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
      interestWaived: interestWaived ?? this.interestWaived,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'dueDate': dueDate,
        'amount': amount,
        'principal': principal,
        'interest': interest,
        'paid': paid,
        'paymentDate': paymentDate,
        'interestWaived': interestWaived,
      };

  factory Installment.fromJson(Map<String, dynamic> json) => Installment(
        number: (json['number'] as num).toInt(),
        dueDate: json['dueDate'] as String,
        amount: (json['amount'] as num).toDouble(),
        principal: (json['principal'] as num?)?.toDouble() ??
            (json['amount'] as num).toDouble(),
        interest: (json['interest'] as num?)?.toDouble() ?? 0,
        paid: json['paid'] as bool? ?? false,
        paymentDate: json['paymentDate'] as String?,
        interestWaived: json['interestWaived'] as bool? ?? false,
      );
}
