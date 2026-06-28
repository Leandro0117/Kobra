import 'api_client.dart';
import '../models/negocio.dart';

class NegocioService {
  /// Devuelve null si todavía no se ha registrado info del negocio.
  Future<Negocio?> obtener() async {
    final response = await ApiClient.get<Map<String, dynamic>>('/negocio');
    if (response.data == null) return null;
    return Negocio.fromJson(response.data!);
  }

  Future<Negocio> guardar(Negocio negocio) async {
    final response = await ApiClient.patch<Map<String, dynamic>>(
      '/negocio',
      data: negocio.toJson(),
    );
    return Negocio.fromJson(response.data!);
  }
}
