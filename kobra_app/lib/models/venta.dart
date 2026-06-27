import 'cliente.dart';
import 'detalle_venta.dart';

enum EstadoVenta { PENDIENTE, POR_PAGAR, PAGADO, CANCELADO }

EstadoVenta estadoFromString(String value) {
  return EstadoVenta.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoVenta.PENDIENTE,
  );
}

String estadoLabel(EstadoVenta estado) {
  switch (estado) {
    case EstadoVenta.PENDIENTE:
      return 'Pendiente';
    case EstadoVenta.POR_PAGAR:
      return 'Por pagar';
    case EstadoVenta.PAGADO:
      return 'Pagado';
    case EstadoVenta.CANCELADO:
      return 'Cancelado';
  }
}

class VendedorResumen {
  final int id;
  final String nombre;
  final String email;

  VendedorResumen({required this.id, required this.nombre, required this.email});

  factory VendedorResumen.fromJson(Map<String, dynamic> json) {
    return VendedorResumen(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
    );
  }
}

class Venta {
  final int id;
  final int vendedorId;
  final int clienteId;
  final DateTime fecha;
  final EstadoVenta estado;
  final double total;
  final Cliente? cliente;
  final VendedorResumen? vendedor;
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    required this.vendedorId,
    required this.clienteId,
    required this.fecha,
    required this.estado,
    required this.total,
    this.cliente,
    this.vendedor,
    this.detalles = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int,
      vendedorId: json['vendedorId'] as int,
      clienteId: json['clienteId'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: estadoFromString(json['estado'] as String),
      total: (json['total'] as num).toDouble(),
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      vendedor: json['vendedor'] != null
          ? VendedorResumen.fromJson(json['vendedor'] as Map<String, dynamic>)
          : null,
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
              .map((d) => DetalleVenta.fromJson(d as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
