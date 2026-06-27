import 'package:flutter/foundation.dart';
import '../models/cliente.dart';
import '../services/clientes_service.dart';
import '../services/api_exception.dart';
import 'carga_lenta_mixin.dart';

class ClientesProvider extends ChangeNotifier with CargaLentaMixin {
  final ClientesService _service = ClientesService();

  List<Cliente> _clientes = [];
  bool _cargando = false;
  String? _error;

  List<Cliente> get clientes => _clientes;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    iniciarAvisoServidorLento(notifyListeners);
    notifyListeners();

    try {
      _clientes = await _service.listar();
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
      _clientes = [..._clientes, nuevo]..sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
