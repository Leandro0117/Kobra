import 'cliente.dart';
import 'detalle_venta.dart';
import 'medio_pago.dart';

enum EstadoVenta { PENDIENTE, POR_PAGAR, PAGADO, CANCELADO }

enum TipoDescuento { PORCENTAJE, MONTO_FIJO }

TipoDescuento tipoDescuentoFromString(String value) {
  return TipoDescuento.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TipoDescuento.PORCENTAJE,
  );
}

EstadoVenta estadoFromString(String value) {
  return EstadoVenta.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoVenta.PENDIENTE,
  );
}

/// Ventas que todavía requieren acción (cobrar, entregar, etc.).
const estadosEnCurso = [EstadoVenta.PENDIENTE, EstadoVenta.POR_PAGAR];

/// Ventas ya cerradas, sea porque se pagaron o porque se cancelaron.
const estadosHistorial = [EstadoVenta.PAGADO, EstadoVenta.CANCELADO];

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
  final double descuento;
  final TipoDescuento tipoDescuento;
  final double montoPagado;
  final MedioPago? medioPago;
  final Cliente? cliente;
  final VendedorResumen? vendedor;
  final List<DetalleVenta> detalles;
  final DateTime? fechaEntregaProgramada;
  final DateTime? fechaEntrega;
  final DateTime? fechaPago;

  Venta({
    required this.id,
    required this.vendedorId,
    required this.clienteId,
    required this.fecha,
    required this.estado,
    required this.total,
    this.descuento = 0,
    this.tipoDescuento = TipoDescuento.PORCENTAJE,
    this.montoPagado = 0,
    this.medioPago,
    this.cliente,
    this.vendedor,
    this.detalles = const [],
    this.fechaEntregaProgramada,
    this.fechaEntrega,
    this.fechaPago,
  });

  double get saldoPendiente => (total - montoPagado).clamp(0, double.infinity);
  double get porcentajePagado => total > 0 ? (montoPagado / total).clamp(0.0, 1.0) : 0;

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] as int,
      vendedorId: (json['vendedorId'] as int?) ?? (json['vendedor']?['id'] as int? ?? 0),
      clienteId: (json['clienteId'] as int?) ?? (json['cliente']?['id'] as int? ?? 0),
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      estado: estadoFromString(json['estado'] as String),
      total: (json['total'] as num).toDouble(),
      descuento: (json['descuento'] as num? ?? 0).toDouble(),
      tipoDescuento: tipoDescuentoFromString(json['tipoDescuento'] as String? ?? 'PORCENTAJE'),
      montoPagado: (json['montoPagado'] as num? ?? 0).toDouble(),
      medioPago: json['medioPago'] != null
          ? MedioPago.fromJson(json['medioPago'] as Map<String, dynamic>)
          : null,
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
      fechaEntregaProgramada: json['fechaEntregaProgramada'] != null
          ? DateTime.parse(json['fechaEntregaProgramada'] as String).toLocal()
          : null,
      fechaEntrega: json['fechaEntrega'] != null
          ? DateTime.parse(json['fechaEntrega'] as String).toLocal()
          : null,
      fechaPago: json['fechaPago'] != null
          ? DateTime.parse(json['fechaPago'] as String).toLocal()
          : null,
    );
  }
}
