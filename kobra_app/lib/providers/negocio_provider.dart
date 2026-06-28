import 'package:flutter/foundation.dart';
import '../models/negocio.dart';
import '../services/negocio_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';

class NegocioProvider extends ChangeNotifier with CargaLentaMixin {
  final NegocioService _service = NegocioService();

  Negocio? _negocio;
  bool _cargando = false;
  // Distingue "todavía no se intentó cargar" de "se cargó y no hay negocio".
  bool _verificado = false;
  String? _error;

  Negocio? get negocio => _negocio;
  bool get cargando => _cargando;
  bool get verificado => _verificado;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _negocio = await _service.obtener();
      _verificado = true;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> guardar(Negocio negocio) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _negocio = await _service.guardar(negocio);
      _verificado = true;
      _cargando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  void reiniciar() {
    _negocio = null;
    _verificado = false;
    _error = null;
  }
}
