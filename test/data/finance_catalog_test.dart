import 'package:flutter_test/flutter_test.dart';
import 'package:krezium/data/finance_categories_catalog.dart';

void main() {
  test('catálogo tiene exactamente 30 categorías', () {
    expect(catalogoFinanzas.length, 30);
  });

  test('ids únicos en catálogo', () {
    final ids = catalogoFinanzas.map((c) => c.id).toSet();
    expect(ids.length, 30);
  });

  test('8 ingresos y 22 gastos', () {
    final ingresos = catalogoFinanzas.where((c) => c.tipo == 'ingreso').length;
    final gastos = catalogoFinanzas.where((c) => c.tipo == 'gasto').length;
    expect(ingresos, 8);
    expect(gastos, 22);
  });
}
