class FinanzasFiltros {
  final String periodo; // 'diario'|'semanal'|'mensual'|'todo'
  final bool ascending;
  final String densidad; // 'comodo'|'compacto'
  final String tipoFiltro; // 'todos'|'ingreso'|'gasto'

  const FinanzasFiltros({
    this.periodo = 'mensual',
    this.ascending = false,
    this.densidad = 'comodo',
    this.tipoFiltro = 'todos',
  });

  FinanzasFiltros copyWith({
    String? periodo,
    bool? ascending,
    String? densidad,
    String? tipoFiltro,
  }) =>
      FinanzasFiltros(
        periodo: periodo ?? this.periodo,
        ascending: ascending ?? this.ascending,
        densidad: densidad ?? this.densidad,
        tipoFiltro: tipoFiltro ?? this.tipoFiltro,
      );
}
