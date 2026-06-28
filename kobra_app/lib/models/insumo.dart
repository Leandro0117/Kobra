class Insumo {
  final int id;
  final String nombre;
  final String? unidad;

  Insumo({required this.id, required this.nombre, this.unidad});

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      unidad: json['unidad'] as String?,
    );
  }
}
