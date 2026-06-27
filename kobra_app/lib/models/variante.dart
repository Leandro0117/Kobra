import 'producto.dart';

/// Una combinación concreta y vendible de un producto base: tamaño y/o
/// topping ya resuelto, con su propio precio (ej. "250g mermelada de fresa").
class Variante {
  final int id;
  final int productoId;
  final String nombre;
  final double precio;
  final Producto? producto;

  Variante({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.producto,
  });

  factory Variante.fromJson(Map<String, dynamic> json) {
    return Variante(
      id: json['id'] as int,
      productoId: json['productoId'] as int,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      producto: json['producto'] != null
          ? Producto.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Nombre completo para mostrar en listas, ej. "Yogurt griego — 250g mermelada de fresa".
  String nombreCompleto() {
    final base = producto?.nombre;
    return base != null ? '$base — $nombre' : nombre;
  }
}
