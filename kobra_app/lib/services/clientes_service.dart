import 'api_client.dart';
import '../models/cliente.dart';

class ClientesService {
  Future<List<Cliente>> listar() async {
    final response = await ApiClient.get<List<dynamic>>('/clientes');
    return response.data!.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Cliente> crear({required String nombre, String? telefono}) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/clientes',
      data: {
        'nombre': nombre,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      },
    );
    return Cliente.fromJson(response.data!);
  }
}
