class MedioPago {
  final int id;
  final String nombre;
  final bool activo;
  final bool esDefault;

  MedioPago({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.esDefault,
  });

  factory MedioPago.fromJson(Map<String, dynamic> json) {
    return MedioPago(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool? ?? true,
      esDefault: json['esDefault'] as bool? ?? false,
    );
  }
}
