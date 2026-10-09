import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/pago_realizado.dart';
import 'database_provider.dart';

final pagosRealizadosProvider =
    FutureProvider.family<List<PagoRealizado>, String>((ref, creditId) async {
  final db = ref.read(databaseProvider);
  return db.loadPagosRealizados(creditId);
});
