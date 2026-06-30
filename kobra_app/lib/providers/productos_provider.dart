import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/productos_service.dart';
import '../services/variantes_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';
import 'cache_mixin.dart';

class ProductosProvider extends ChangeNotifier with CargaLentaMixin, CacheMixin {
  final ProductosService _service = ProductosService();
  final VariantesService _variantesService = VariantesService();

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar({bool forzar = false}) async {
    if (!forzar && cacheVigente(const Duration(minutes: 5)) && _productos.isNotEmpty) return;

    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _productos = await _service.listar();
      marcarCargado();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(String nombre) async {
    _error = null;
    try {
      final nuevo = await _service.crear(nombre);
      _productos = [..._productos, nuevo]..sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizar(int id, String nombre) async {
    _error = null;
    try {
      await _service.actualizar(id, nombre);
      return _refrescarProducto(id);
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _refrescarProducto(int productoId) async {
    try {
      final actualizado = await _service.obtener(productoId);
      _productos = _productos.map((p) => p.id == productoId ? actualizado : p).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> agregarVariante(
    int productoId,
    String nombre,
    double precio, {
    double? costo,
  }) async {
    _error = null;
    try {
      await _variantesService.crear(
        productoId: productoId,
        nombre: nombre,
        precio: precio,
        costo: costo,
      );
      return _refrescarProducto(productoId);
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarVariante(
    int productoId,
    int varianteId, {
    String? nombre,
    double? precio,
    double? costo,
  }) async {
    _error = null;
    try {
      await _variantesService.actualizar(varianteId, nombre: nombre, precio: precio, costo: costo);
      return _refrescarProducto(productoId);
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarVariante(int productoId, int varianteId) async {
    _error = null;
    try {
      await _variantesService.eliminar(varianteId);
      return _refrescarProducto(productoId);
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
      _productos = _productos.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  /// Elimina varios productos. Devuelve un mapa id -> mensaje de error
  /// (null si ese producto se eliminó correctamente), para que la pantalla
  /// pueda mostrar un resumen de qué falló y por qué.
  Future<Map<int, String?>> eliminarVarios(List<int> ids) async {
    final resultados = <int, String?>{};
    for (final id in ids) {
      try {
        await _service.eliminar(id);
        resultados[id] = null;
      } on ApiException catch (e) {
        resultados[id] = e.mensaje;
      }
    }

    final idsEliminados = resultados.entries.where((e) => e.value == null).map((e) => e.key);
    _productos = _productos.where((p) => !idsEliminados.contains(p.id)).toList();
    notifyListeners();
    return resultados;
  }
}
