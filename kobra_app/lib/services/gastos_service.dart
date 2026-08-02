import 'api_client.dart';
import '../models/gasto.dart';
import '../models/detalle_gasto.dart';
import '../models/categoria_gasto.dart';

class FiltroGastos {
  final int? proveedorId;
  final CategoriaGasto? categoria;
  final DateTime? desde;
  final DateTime? hasta;

  FiltroGastos({this.proveedorId, this.categoria, this.desde, this.hasta});

  static FiltroGastos mesActual() {
    final now = DateTime.now();
    return FiltroGastos(
      desde: DateTime(now.year, now.month, 1),
      hasta: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  Map<String, dynamic> toQuery() => {
        if (proveedorId != null) 'proveedorId': proveedorId,
        if (categoria != null) 'categoria': categoria!.name,
        if (desde != null) 'desde': desde!.toUtc().toIso8601String(),
        if (hasta != null) 'hasta': hasta!.toUtc().toIso8601String(),
      };
}

class GastosService {
  Future<List<Gasto>> listar(FiltroGastos filtro) async {
    final response = await ApiClient.get<List<dynamic>>('/gastos', query: filtro.toQuery());
    return response.data!.map((e) => Gasto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Gasto> obtener(int id) async {
    final response = await ApiClient.get<Map<String, dynamic>>('/gastos/$id');
    return Gasto.fromJson(response.data!);
  }

  Future<Gasto> crear({
    int? proveedorId,
    required CategoriaGasto categoria,
    required List<DetalleGasto> detalles,
  }) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/gastos',
      data: {
        'proveedorId': ?proveedorId,
        'categoria': categoria.name,
        'detalles': detalles.map((d) => d.toCreateJson()).toList(),
      },
    );
    return Gasto.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/gastos/$id');
  }
}
