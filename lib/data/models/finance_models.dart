import 'package:krezium/data/db/database.dart';

class FinanceAccount {
  final String id;
  final String nombre;
  final String tipo;
  final String icono;
  final String color;
  final double saldoInicial;
  final bool activa;
  final String orden;
  final bool esFavorito;

  const FinanceAccount({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.saldoInicial,
    required this.activa,
    required this.orden,
    this.esFavorito = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'tipo': tipo, 'icono': icono,
    'color': color, 'saldoInicial': saldoInicial, 'activa': activa,
    'orden': orden, 'esFavorito': esFavorito,
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
    esFavorito: json['esFavorito'] as bool? ?? false,
  );
}

class FinanceCategory {
  final String id;
  final String nombre;
  final String icono;
  final String color;
  final String tipo;
  final bool archivada;
  final String? parentId;

  const FinanceCategory({
    required this.id, required this.nombre, required this.icono,
    required this.color, required this.tipo, required this.archivada,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'icono': icono,
    'color': color, 'tipo': tipo, 'archivada': archivada,
    'parentId': parentId,
  };

  factory FinanceCategory.fromJson(Map<String, dynamic> json) => FinanceCategory(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    icono: json['icono'] as String? ?? 'label',
    color: json['color'] as String? ?? '#6B7280',
    tipo: json['tipo'] as String? ?? 'gasto',
    archivada: json['archivada'] as bool? ?? false,
    parentId: json['parentId'] as String?,
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
  final String? personaSitio;
  final String? hora;
  final String? transferToAccountId;

  const FinanceTransaction({
    required this.id, required this.accountId, required this.categoryId,
    required this.tipo, required this.monto, required this.fecha,
    required this.nota, required this.esRecurrente, this.recurrenciaConfig,
    this.personaSitio, this.hora, this.transferToAccountId,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'accountId': accountId, 'categoryId': categoryId,
    'tipo': tipo, 'monto': monto, 'fecha': fecha, 'nota': nota,
    'esRecurrente': esRecurrente, 'recurrenciaConfig': recurrenciaConfig,
    'personaSitio': personaSitio, 'hora': hora,
    'transferToAccountId': transferToAccountId,
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
    personaSitio: json['personaSitio'] as String?,
    hora: json['hora'] as String?,
    transferToAccountId: json['transferToAccountId'] as String?,
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

class FinancePlace {
  final String id;
  final String nombre;
  final int usados;

  const FinancePlace({required this.id, required this.nombre, required this.usados});

  factory FinancePlace.fromRow(FinancePlaceRow row) =>
      FinancePlace(id: row.id, nombre: row.nombre, usados: row.usados);

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'usados': usados};

  factory FinancePlace.fromJson(Map<String, dynamic> json) => FinancePlace(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    usados: json['usados'] as int? ?? 0,
  );
}

class FinanceTemplate {
  final String id;
  final String nombre;
  final String? libroId;
  final String categoryId;
  final String tipo;
  final double? monto;
  final String? personaSitio;
  final String? nota;

  const FinanceTemplate({
    required this.id, required this.nombre, this.libroId,
    required this.categoryId, required this.tipo,
    this.monto, this.personaSitio, this.nota,
  });

  factory FinanceTemplate.fromRow(FinanceTemplateRow row) => FinanceTemplate(
    id: row.id, nombre: row.nombre, libroId: row.libroId,
    categoryId: row.categoryId, tipo: row.tipo, monto: row.monto,
    personaSitio: row.personaSitio, nota: row.nota,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'libroId': libroId,
    'categoryId': categoryId, 'tipo': tipo, 'monto': monto,
    'personaSitio': personaSitio, 'nota': nota,
  };

  factory FinanceTemplate.fromJson(Map<String, dynamic> json) => FinanceTemplate(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    libroId: json['libroId'] as String?,
    categoryId: json['categoryId'] as String,
    tipo: json['tipo'] as String? ?? 'gasto',
    monto: (json['monto'] as num?)?.toDouble(),
    personaSitio: json['personaSitio'] as String?,
    nota: json['nota'] as String?,
  );
}
