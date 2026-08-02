import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';

class FiltroVentas {
  final int? vendedorId;
  final int? clienteId;
  final EstadoVenta? estado;
  final DateTime? desde;
  final DateTime? hasta;

  FiltroVentas({this.vendedorId, this.clienteId, this.estado, this.desde, this.hasta});

  static FiltroVentas mesActual() {
    final now = DateTime.now();
    return FiltroVentas(
      desde: DateTime(now.year, now.month, 1),
      hasta: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  Map<String, dynamic> toQuery() => {
        if (vendedorId != null) 'vendedorId': vendedorId,
        if (clienteId != null) 'clienteId': clienteId,
        if (estado != null) 'estado': estado!.name,
        if (desde != null) 'desde': desde!.toUtc().toIso8601String(),
        if (hasta != null) 'hasta': hasta!.toUtc().toIso8601String(),
      };
}

class VentasService {
  Future<List<Venta>> listar(FiltroVentas filtro) async {
    final response = await ApiClient.get<List<dynamic>>('/ventas', query: filtro.toQuery());
    return response.data!.map((e) => Venta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Venta> obtener(int id) async {
    final response = await ApiClient.get<Map<String, dynamic>>('/ventas/$id');
    return Venta.fromJson(response.data!);
  }

  Future<Venta> crear({
    int? clienteId,
    required List<DetalleVenta> detalles,
    EstadoVenta? estado,
    double descuento = 0,
    TipoDescuento tipoDescuento = TipoDescuento.PORCENTAJE,
    int? medioPagoId,
    DateTime? fechaVenta,
    DateTime? fechaEntregaProgramada,
  }) async {
    final payload = {
      'clienteId': ?clienteId,
      if (estado != null) 'estado': estado.name,
      'descuento': descuento,
      'tipoDescuento': tipoDescuento.name,
      'medioPagoId': ?medioPagoId,
      if (fechaVenta != null) 'fechaVenta': fechaVenta.toUtc().toIso8601String(),
      if (fechaEntregaProgramada != null)
        'fechaEntregaProgramada': fechaEntregaProgramada.toUtc().toIso8601String(),
      'detalles': detalles.map((d) => d.toCreateJson()).toList(),
    };
    debugPrint('[VentasService.crear] payload: $payload');
    try {
      final response = await ApiClient.post<Map<String, dynamic>>('/ventas', data: payload);
      final venta = Venta.fromJson(response.data!);
      debugPrint('[VentasService.crear] OK id=${venta.id} estado=${venta.estado.name} total=${venta.total}');
      return venta;
    } catch (e, st) {
      debugPrint('[VentasService.crear] ERROR: $e\n$st');
      rethrow;
    }
  }

  Future<Venta> cambiarEstado(int id, EstadoVenta estado) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/ventas/$id/estado',
      data: {'estado': estado.name},
    );
    return Venta.fromJson(response.data!);
  }

  Future<Venta> actualizar(
    int id, {
    required List<DetalleVenta> detalles,
    int? clienteId,
    double? descuento,
    TipoDescuento? tipoDescuento,
    int? medioPagoId,
  }) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/ventas/$id',
      data: {
        'clienteId': ?clienteId,
        'descuento': ?descuento,
        'tipoDescuento': ?tipoDescuento?.name,
        'medioPagoId': ?medioPagoId,
        'detalles': detalles.map((d) => d.toCreateJson()).toList(),
      },
    );
    return Venta.fromJson(response.data!);
  }

  Future<Venta> registrarPago(int id, double monto, {int? medioPagoId}) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/ventas/$id/pago',
      data: {
        'monto': monto,
        'medioPagoId': ?medioPagoId,
      },
    );
    return Venta.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/ventas/$id');
  }
}
