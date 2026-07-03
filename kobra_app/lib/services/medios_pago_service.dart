import 'api_client.dart';
import '../models/medio_pago.dart';

class MediosPagoService {
  Future<List<MedioPago>> listar() async {
    final response = await ApiClient.get<List<dynamic>>('/medios-pago');
    return response.data!.map((e) => MedioPago.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MedioPago> crear(String nombre) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/medios-pago',
      data: {'nombre': nombre},
    );
    return MedioPago.fromJson(response.data!);
  }

  Future<MedioPago> toggleActivo(int id) async {
    final response = await ApiClient.patch<Map<String, dynamic>>('/medios-pago/$id/toggle');
    return MedioPago.fromJson(response.data!);
  }

  Future<void> eliminar(int id) async {
    await ApiClient.delete('/medios-pago/$id');
  }
}
