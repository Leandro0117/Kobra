import 'package:flutter/foundation.dart';
import '../models/gasto.dart';
import '../models/detalle_gasto.dart';
import '../models/categoria_gasto.dart';
import '../services/gastos_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';
import 'cache_mixin.dart';

class GastosProvider extends ChangeNotifier with CargaLentaMixin, CacheMixin {
  final GastosService _service = GastosService();

  List<Gasto> _gastos = [];
  bool _cargando = false;
  String? _error;
  FiltroGastos _filtroActual = FiltroGastos();

  List<Gasto> get gastos => _gastos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar({FiltroGastos? filtro, bool forzar = false}) async {
    final nuevoFiltro = filtro ?? _filtroActual;
    final clave = nuevoFiltro.toQuery().toString();

    if (!forzar && cacheVigente(const Duration(minutes: 2), clave: clave) && _gastos.isNotEmpty) {
      _filtroActual = nuevoFiltro;
      return;
    }

    _filtroActual = nuevoFiltro;
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _gastos = await _service.listar(_filtroActual);
      marcarCargado(clave: clave);
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<Gasto?> crear({
    required int proveedorId,
    required CategoriaGasto categoria,
    required List<DetalleGasto> detalles,
  }) async {
    _error = null;
    try {
      final gasto = await _service.crear(
        proveedorId: proveedorId,
        categoria: categoria,
        detalles: detalles,
      );
      _gastos = [gasto, ..._gastos];
      notifyListeners();
      return gasto;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<Gasto?> obtener(int id) async {
    _error = null;
    try {
      return await _service.obtener(id);
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<bool> eliminar(int id) async {
    _error = null;
    try {
      await _service.eliminar(id);
      _gastos = _gastos.where((g) => g.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
