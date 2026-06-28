class Proveedor {
  final int id;
  final String nombre;
  final String? telefono;

  Proveedor({required this.id, required this.nombre, this.telefono});

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
    );
  }
}
