import 'package:flutter/foundation.dart';
import '../models/insumo.dart';
import '../services/insumos_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';
import 'cache_mixin.dart';

class InsumosProvider extends ChangeNotifier with CargaLentaMixin, CacheMixin {
  final InsumosService _service = InsumosService();

  List<Insumo> _insumos = [];
  bool _cargando = false;
  String? _error;

  List<Insumo> get insumos => _insumos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar({bool forzar = false}) async {
    if (!forzar && cacheVigente(const Duration(minutes: 10)) && _insumos.isNotEmpty) return;

    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _insumos = await _service.listar();
      marcarCargado();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(String nombre, UnidadInsumo? unidad, double? precio) async {
    _error = null;
    try {
      final nuevo = await _service.crear(nombre: nombre, unidad: unidad, precio: precio);
      _insumos = [..._insumos, nuevo]..sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    _error = null;
    try {
      await _service.eliminar(id);
      _insumos = _insumos.where((i) => i.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
