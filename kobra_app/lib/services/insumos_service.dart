import 'api_client.dart';
import '../models/insumo.dart';

class InsumosService {
  Future<List<Insumo>> listar() async {
    final response = await ApiClient.get<List<dynamic>>('/insumos');
    return response.data!.map((e) => Insumo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Insumo> crear({required String nombre, String? unidad}) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/insumos',
      data: {
        'nombre': nombre,
        if (unidad != null && unidad.isNotEmpty) 'unidad': unidad,
      },
    );
    return Insumo.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/insumos/$id');
  }
}
