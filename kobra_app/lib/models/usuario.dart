enum Rol { ADMIN, VENDEDOR }

Rol rolFromString(String value) {
  return Rol.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Rol.VENDEDOR,
  );
}

class Usuario {
  final int id;
  final int negocioId;
  final String nombre;
  final String email;
  final Rol rol;

  Usuario({
    required this.id,
    required this.negocioId,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      negocioId: json['negocioId'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: rolFromString(json['rol'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'negocioId': negocioId,
        'nombre': nombre,
        'email': email,
        'rol': rol.name,
      };
}
