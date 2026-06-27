import 'api_client.dart';
import '../models/variante.dart';

class VariantesService {
  Future<Variante> crear({required int productoId, required String nombre, required double precio}) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/productos/$productoId/variantes',
      data: {'nombre': nombre, 'precio': precio},
    );
    return Variante.fromJson(response.data!);
  }

  Future<Variante> actualizar(int id, {String? nombre, double? precio}) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/variantes/$id',
      data: {
        if (nombre != null) 'nombre': nombre,
        if (precio != null) 'precio': precio,
      },
    );
    return Variante.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/variantes/$id');
  }
}
