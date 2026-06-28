class Negocio {
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String moneda;

  Negocio({
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.moneda,
  });

  factory Negocio.fromJson(Map<String, dynamic> json) {
    return Negocio(
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      moneda: json['moneda'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (direccion != null) 'direccion': direccion,
        if (telefono != null) 'telefono': telefono,
        'moneda': moneda,
      };
}
