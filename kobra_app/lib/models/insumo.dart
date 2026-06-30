enum UnidadInsumo { UNIDAD, KG, G, L, ML, M, CM, PAQ, CAJA, DOC }

String unidadInsumoLabel(UnidadInsumo u) {
  switch (u) {
    case UnidadInsumo.UNIDAD: return 'Unidad (u.)';
    case UnidadInsumo.KG:     return 'Kilogramo (kg)';
    case UnidadInsumo.G:      return 'Gramo (g)';
    case UnidadInsumo.L:      return 'Litro (L)';
    case UnidadInsumo.ML:     return 'Mililitro (mL)';
    case UnidadInsumo.M:      return 'Metro (m)';
    case UnidadInsumo.CM:     return 'Centímetro (cm)';
    case UnidadInsumo.PAQ:    return 'Paquete';
    case UnidadInsumo.CAJA:   return 'Caja';
    case UnidadInsumo.DOC:    return 'Docena';
  }
}

class Insumo {
  final int id;
  final String nombre;
  final UnidadInsumo? unidad;
  final double? precio;

  Insumo({required this.id, required this.nombre, this.unidad, this.precio});

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      unidad: json['unidad'] != null
          ? UnidadInsumo.values.byName(json['unidad'] as String)
          : null,
      precio: json['precio'] != null ? (json['precio'] as num).toDouble() : null,
    );
  }
}
