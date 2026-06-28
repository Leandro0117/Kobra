enum CategoriaGasto { INSUMOS, EQUIPAMIENTO, SERVICIOS, TRANSPORTE, OTRO }

CategoriaGasto categoriaGastoFromString(String value) {
  return CategoriaGasto.values.firstWhere(
    (c) => c.name == value,
    orElse: () => CategoriaGasto.OTRO,
  );
}

String categoriaGastoLabel(CategoriaGasto categoria) {
  switch (categoria) {
    case CategoriaGasto.INSUMOS:
      return 'Insumos';
    case CategoriaGasto.EQUIPAMIENTO:
      return 'Equipamiento';
    case CategoriaGasto.SERVICIOS:
      return 'Servicios';
    case CategoriaGasto.TRANSPORTE:
      return 'Transporte';
    case CategoriaGasto.OTRO:
      return 'Otro';
  }
}
