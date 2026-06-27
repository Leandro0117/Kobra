import 'variante.dart';

class DetalleVenta {
  final int? id;
  final int varianteId;
  final double cantidad;
  final double precioUnitario;
  final Variante? variante;

  DetalleVenta({
    this.id,
    required this.varianteId,
    required this.cantidad,
    required this.precioUnitario,
    this.variante,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: json['id'] as int?,
      varianteId: json['varianteId'] as int,
      cantidad: (json['cantidad'] as num).toDouble(),
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      variante: json['variante'] != null
          ? Variante.fromJson(json['variante'] as Map<String, dynamic>)
          : null,
    );
  }

  double get subtotal => cantidad * precioUnitario;

  /// Lo que se envía al backend al crear una venta (sin precioUnitario:
  /// el backend lo calcula a partir del precio actual de la variante).
  Map<String, dynamic> toCreateJson() => {
        'varianteId': varianteId,
        'cantidad': cantidad,
      };
}
