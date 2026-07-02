import 'api_client.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';

class FiltroVentas {
  final int? vendedorId;
  final int? clienteId;
  final EstadoVenta? estado;

  FiltroVentas({this.vendedorId, this.clienteId, this.estado});

  Map<String, dynamic> toQuery() => {
        if (vendedorId != null) 'vendedorId': vendedorId,
        if (clienteId != null) 'clienteId': clienteId,
        if (estado != null) 'estado': estado!.name,
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
    required int clienteId,
    required List<DetalleVenta> detalles,
    EstadoVenta? estado,
  }) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/ventas',
      data: {
        'clienteId': clienteId,
        if (estado != null) 'estado': estado.name,
        'detalles': detalles.map((d) => d.toCreateJson()).toList(),
      },
    );
    return Venta.fromJson(response.data!);
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
  }) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/ventas/$id',
      data: {
        'clienteId': ?clienteId,
        'detalles': detalles.map((d) => d.toCreateJson()).toList(),
      },
    );
    return Venta.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/ventas/$id');
  }
}
