import 'package:flutter/foundation.dart';
import '../models/venta.dart';
import '../models/detalle_venta.dart';
import '../services/ventas_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';
import 'cache_mixin.dart';

class VentasProvider extends ChangeNotifier with CargaLentaMixin, CacheMixin {
  final VentasService _service = VentasService();

  List<Venta> _ventas = [];
  bool _cargando = false;
  String? _error;
  FiltroVentas _filtroActual = FiltroVentas();

  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;
  String? get error => _error;
  FiltroVentas get filtroActual => _filtroActual;

  Future<void> cargar({FiltroVentas? filtro, bool forzar = false}) async {
    final nuevoFiltro = filtro ?? _filtroActual;
    final clave = nuevoFiltro.toQuery().toString();

    if (!forzar && cacheVigente(const Duration(minutes: 2), clave: clave) && _ventas.isNotEmpty) {
      _filtroActual = nuevoFiltro;
      return;
    }

    _filtroActual = nuevoFiltro;
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _ventas = await _service.listar(_filtroActual);
      marcarCargado(clave: clave);
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<Venta?> crear({
    required int clienteId,
    required List<DetalleVenta> detalles,
    EstadoVenta? estado,
  }) async {
    _error = null;
    try {
      final venta = await _service.crear(
        clienteId: clienteId,
        detalles: detalles,
        estado: estado,
      );
      _ventas = [venta, ..._ventas];
      notifyListeners();
      return venta;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<Venta?> obtener(int id) async {
    _error = null;
    try {
      return await _service.obtener(id);
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return null;
    }
  }

  Future<Venta?> cambiarEstado(int id, EstadoVenta estado) async {
    _error = null;
    try {
      final actualizada = await _service.cambiarEstado(id, estado);
      _ventas = _ventas.map((v) => v.id == id ? actualizada : v).toList();
      notifyListeners();
      return actualizada;
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
      _ventas = _ventas.where((v) => v.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
