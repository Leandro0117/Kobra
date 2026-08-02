import 'insumo.dart';

class DetalleGasto {
  final int? id;
  final int? insumoId;
  final String? concepto;
  final double cantidad;
  final double precioUnitario;
  final Insumo? insumo;

  DetalleGasto({
    this.id,
    this.insumoId,
    this.concepto,
    required this.cantidad,
    required this.precioUnitario,
    this.insumo,
  });

  factory DetalleGasto.fromJson(Map<String, dynamic> json) {
    return DetalleGasto(
      id: json['id'] as int?,
      insumoId: json['insumoId'] as int?,
      concepto: json['concepto'] as String?,
      cantidad: (json['cantidad'] as num).toDouble(),
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      insumo: json['insumo'] != null
          ? Insumo.fromJson(json['insumo'] as Map<String, dynamic>)
          : null,
    );
  }

  double get subtotal => cantidad * precioUnitario;

  String get nombre => insumo?.nombre ?? concepto ?? (insumoId != null ? 'Insumo #$insumoId' : 'Ítem');

  Map<String, dynamic> toCreateJson() {
    if (insumoId != null) {
      return {
        'insumoId': insumoId,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };
    }
    return {
      'concepto': concepto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
    };
  }
}
