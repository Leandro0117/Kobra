import 'package:flutter/foundation.dart';
import '../models/estadisticas.dart';
import '../services/estadisticas_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';

class EstadisticasProvider extends ChangeNotifier with CargaLentaMixin {
  final EstadisticasService _service = EstadisticasService();

  ResumenEstadisticas? _resumen;
  bool _cargando = false;
  String? _error;
  PeriodoEstadisticas _periodo = PeriodoEstadisticas.todo;

  ResumenEstadisticas? get resumen => _resumen;
  bool get cargando => _cargando;
  String? get error => _error;
  PeriodoEstadisticas get periodo => _periodo;

  Future<void> cargar({PeriodoEstadisticas? periodo}) async {
    _periodo = periodo ?? _periodo;
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _resumen = await _service.obtenerResumen(_periodo);
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }
}
