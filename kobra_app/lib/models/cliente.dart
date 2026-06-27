class Cliente {
  final int id;
  final String nombre;
  final String? telefono;

  Cliente({required this.id, required this.nombre, this.telefono});

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
    );
  }
}
