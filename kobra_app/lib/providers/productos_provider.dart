import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/productos_service.dart';
import '../services/variantes_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';

class ProductosProvider extends ChangeNotifier with CargaLentaMixin {
  final ProductosService _service = ProductosService();
  final VariantesService _variantesService = VariantesService();

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _productos = await _service.listar();
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
      final actualizado = await _service.actualizar(id, nombre);
      _productos = _productos.map((p) => p.id == id ? actualizado : p).toList();
      notifyListeners();
      return true;
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

  Future<bool> agregarVariante(int productoId, String nombre, double precio) async {
    _error = null;
    try {
      await _variantesService.crear(productoId: productoId, nombre: nombre, precio: precio);
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
  }) async {
    _error = null;
    try {
      await _variantesService.actualizar(varianteId, nombre: nombre, precio: precio);
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
}
