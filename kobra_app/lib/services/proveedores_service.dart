import 'api_client.dart';
import '../models/proveedor.dart';

class ProveedoresService {
  Future<List<Proveedor>> listar() async {
    final response = await ApiClient.get<List<dynamic>>('/proveedores');
    return response.data!.map((e) => Proveedor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Proveedor> crear({required String nombre, String? telefono}) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/proveedores',
      data: {
        'nombre': nombre,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      },
    );
    return Proveedor.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/proveedores/$id');
  }
}
