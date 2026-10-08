/// Pago real registrado manualmente por el usuario.
/// Persiste en la tabla PagosRealizados (v12).
class PagoRealizadoTipo {
  static const cuota = 'cuota';
  static const pagoTarjeta = 'pago_tarjeta';
}

class PagoRealizado {
  /// Autoincremental de la DB — null antes de persistir.
  final int? rowId;
  final String creditId;

  /// "YYYY-MM-DD"
  final String fecha;

  final double monto;

  /// [PagoRealizadoTipo.cuota] | [PagoRealizadoTipo.pagoTarjeta]
  final String tipo;

  /// Solo cuando tipo == 'cuota'.
  final int? numeroCuota;

  final String nota;

  const PagoRealizado({
    this.rowId,
    required this.creditId,
    required this.fecha,
    required this.monto,
    required this.tipo,
    this.numeroCuota,
    this.nota = '',
  });
}
