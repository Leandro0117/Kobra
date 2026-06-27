enum Rol { ADMIN, VENDEDOR }

Rol rolFromString(String value) {
  return Rol.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Rol.VENDEDOR,
  );
}

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final Rol rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: rolFromString(json['rol'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol.name,
      };
}
