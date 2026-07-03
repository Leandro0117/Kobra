import 'package:flutter/foundation.dart';
import '../models/medio_pago.dart';
import '../services/medios_pago_service.dart';
import '../services/api_exception.dart';

class MediosPagoProvider extends ChangeNotifier {
  final MediosPagoService _service = MediosPagoService();

  List<MedioPago> _medios = [];
  bool _cargando = false;
  String? _error;

  List<MedioPago> get medios => _medios;
  List<MedioPago> get mediosActivos => _medios.where((m) => m.activo).toList();
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _medios = await _service.listar();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear(String nombre) async {
    _error = null;
    try {
      final nuevo = await _service.crear(nombre);
      _medios = [..._medios, nuevo];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleActivo(int id) async {
    _error = null;
    try {
      final actualizado = await _service.toggleActivo(id);
      _medios = _medios.map((m) => m.id == id ? actualizado : m).toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
    }
  }

  Future<bool> eliminar(int id) async {
    _error = null;
    try {
      await _service.eliminar(id);
      _medios = _medios.where((m) => m.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }
}
