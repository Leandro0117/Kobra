import 'insumo.dart';

class DetalleGasto {
  final int? id;
  final int insumoId;
  final double cantidad;
  final double precioUnitario;
  final Insumo? insumo;

  DetalleGasto({
    this.id,
    required this.insumoId,
    required this.cantidad,
    required this.precioUnitario,
    this.insumo,
  });

  factory DetalleGasto.fromJson(Map<String, dynamic> json) {
    return DetalleGasto(
      id: json['id'] as int?,
      insumoId: json['insumoId'] as int,
      cantidad: (json['cantidad'] as num).toDouble(),
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      insumo: json['insumo'] != null
          ? Insumo.fromJson(json['insumo'] as Map<String, dynamic>)
          : null,
    );
  }

  double get subtotal => cantidad * precioUnitario;

  /// Lo que se envía al backend al crear un gasto. A diferencia de las ventas,
  /// aquí sí se manda el precioUnitario: es lo que efectivamente se pagó,
  /// no hay un precio "oficial" en el catálogo de insumos.
  Map<String, dynamic> toCreateJson() => {
        'insumoId': insumoId,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };
}
