import 'api_client.dart';
import '../models/producto.dart';

class ProductosService {
  Future<List<Producto>> listar() async {
    final response = await ApiClient.get<List<dynamic>>('/productos');
    return response.data!.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Producto> obtener(int id) async {
    final response = await ApiClient.get<Map<String, dynamic>>('/productos/$id');
    return Producto.fromJson(response.data!);
  }

  Future<Producto> crear(String nombre) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/productos',
      data: {'nombre': nombre},
    );
    return Producto.fromJson(response.data!);
  }

  Future<Producto> actualizar(int id, String nombre) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/productos/$id',
      data: {'nombre': nombre},
    );
    return Producto.fromJson(response.data!);
  }
}
