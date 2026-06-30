import 'api_client.dart';
import '../models/finanzas.dart';
import '../models/estadisticas.dart';

class FinanzasService {
  Future<ResumenFinanzas> obtenerResumen(PeriodoEstadisticas periodo) async {
    final (desde, hasta) = rangoDePeriodo(periodo, DateTime.now());
    final response = await ApiClient.get<Map<String, dynamic>>(
      '/finanzas',
      query: {
        if (desde != null) 'desde': desde.toUtc().toIso8601String(),
        if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
      },
    );
    return ResumenFinanzas.fromJson(response.data!);
  }
}
