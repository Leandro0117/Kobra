import 'package:flutter/foundation.dart';
import '../models/proveedor.dart';
import '../services/proveedores_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';

class ProveedoresProvider extends ChangeNotifier with CargaLentaMixin {
  final ProveedoresService _service = ProveedoresService();

  List<Proveedor> _proveedores = [];
  bool _cargando = false;
  String? _error;

  List<Proveedor> get proveedores => _proveedores;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _proveedores = await _service.listar();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      detenerAvisoServidorLento();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(String nombre, String? telefono) async {
    _error = null;
    try {
      final nuevo = await _service.crear(nombre: nombre, telefono: telefono);
      _proveedores = [..._proveedores, nuevo]..sort((a, b) => a.nombre.compareTo(b.nombre));
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
      _proveedores = _proveedores.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
