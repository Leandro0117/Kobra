import 'variante.dart';

/// Producto base que agrupa variantes (ej. "Yogurt griego" agrupa
/// "250g sin topping", "250g mermelada de fresa", "500g arándanos", etc.).
class Producto {
  final int id;
  final String nombre;
  final List<Variante> variantes;

  Producto({required this.id, required this.nombre, this.variantes = const []});

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      variantes: json['variantes'] != null
          ? (json['variantes'] as List)
              .map((v) => Variante.fromJson(v as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
