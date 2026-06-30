import 'api_client.dart';
import '../models/estadisticas.dart';

class EstadisticasService {
  Future<ResumenEstadisticas> obtenerResumen(PeriodoEstadisticas periodo) async {
    final (desde, hasta) = rangoDePeriodo(periodo, DateTime.now());
    final response = await ApiClient.get<Map<String, dynamic>>(
      '/estadisticas',
      query: {
        if (desde != null) 'desde': desde.toUtc().toIso8601String(),
        if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
      },
    );
    return ResumenEstadisticas.fromJson(response.data!);
  }
}
