class FinanceAccount {
  final String id;
  final String nombre;
  final String tipo;
  final String icono;
  final String color;
  final double saldoInicial;
  final bool activa;
  final String orden;

  const FinanceAccount({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.saldoInicial,
    required this.activa,
    required this.orden,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'tipo': tipo, 'icono': icono,
    'color': color, 'saldoInicial': saldoInicial, 'activa': activa, 'orden': orden,
  };

  factory FinanceAccount.fromJson(Map<String, dynamic> json) => FinanceAccount(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    tipo: json['tipo'] as String? ?? 'efectivo',
    icono: json['icono'] as String? ?? 'account_balance_wallet',
    color: json['color'] as String? ?? '#6B7280',
    saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0.0,
    activa: json['activa'] as bool? ?? true,
    orden: json['orden'] as String? ?? '0',
  );
}

class FinanceCategory {
  final String id;
  final String nombre;
  final String icono;
  final String color;
  final String tipo;
  final bool archivada;

  const FinanceCategory({
    required this.id, required this.nombre, required this.icono,
    required this.color, required this.tipo, required this.archivada,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'icono': icono,
    'color': color, 'tipo': tipo, 'archivada': archivada,
  };

  factory FinanceCategory.fromJson(Map<String, dynamic> json) => FinanceCategory(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    icono: json['icono'] as String? ?? 'label',
    color: json['color'] as String? ?? '#6B7280',
    tipo: json['tipo'] as String? ?? 'gasto',
    archivada: json['archivada'] as bool? ?? false,
  );
}

class FinanceTransaction {
  final String id;
  final String accountId;
  final String categoryId;
  final String tipo;
  final double monto;
  final String fecha;
  final String nota;
  final bool esRecurrente;
  final String? recurrenciaConfig;

  const FinanceTransaction({
    required this.id, required this.accountId, required this.categoryId,
    required this.tipo, required this.monto, required this.fecha,
    required this.nota, required this.esRecurrente, this.recurrenciaConfig,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'accountId': accountId, 'categoryId': categoryId,
    'tipo': tipo, 'monto': monto, 'fecha': fecha, 'nota': nota,
    'esRecurrente': esRecurrente, 'recurrenciaConfig': recurrenciaConfig,
  };

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) => FinanceTransaction(
    id: json['id'] as String,
    accountId: json['accountId'] as String,
    categoryId: json['categoryId'] as String,
    tipo: json['tipo'] as String? ?? 'gasto',
    monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
    fecha: json['fecha'] as String? ?? '',
    nota: json['nota'] as String? ?? '',
    esRecurrente: json['esRecurrente'] as bool? ?? false,
    recurrenciaConfig: json['recurrenciaConfig'] as String?,
  );
}

class FinanceBudget {
  final String categoryId;
  final int anio;
  final int mes;
  final double montoLimite;

  const FinanceBudget({
    required this.categoryId, required this.anio,
    required this.mes, required this.montoLimite,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId, 'anio': anio, 'mes': mes, 'montoLimite': montoLimite,
  };

  factory FinanceBudget.fromJson(Map<String, dynamic> json) => FinanceBudget(
    categoryId: json['categoryId'] as String,
    anio: json['anio'] as int? ?? 0,
    mes: json['mes'] as int? ?? 1,
    montoLimite: (json['montoLimite'] as num?)?.toDouble() ?? 0.0,
  );
}
