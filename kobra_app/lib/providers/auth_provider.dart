import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Usuario? _usuario;
  bool _cargando = false;
  bool _verificandoSesion = true;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get estaAutenticado => _usuario != null;
  bool get cargando => _cargando;
  bool get verificandoSesion => _verificandoSesion;
  String? get error => _error;

  AuthProvider() {
    ApiClient.onUnauthorized = cerrarSesion;
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    try {
      final usuarioJson =
          await TokenStorage.leerUsuarioJson().timeout(const Duration(seconds: 3));
      final token = await TokenStorage.leerToken().timeout(const Duration(seconds: 3));
      if (usuarioJson != null && token != null) {
        _usuario = Usuario.fromJson(jsonDecode(usuarioJson) as Map<String, dynamic>);
      }
    } catch (_) {
    } finally {
      _verificandoSesion = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final resultado = await _authService.login(email, password);
      await TokenStorage.guardarSesion(
        resultado.accessToken,
        jsonEncode(resultado.usuario.toJson()),
      );
      _usuario = resultado.usuario;
      _cargando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
    required String negocioNombre,
    required String negocioMoneda,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registrar(
        nombre: nombre,
        email: email,
        password: password,
        negocioNombre: negocioNombre,
        negocioMoneda: negocioMoneda,
      );
      return await login(email, password);
    } on ApiException catch (e) {
      _error = e.mensaje;
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await TokenStorage.limpiarSesion();
    _usuario = null;
    notifyListeners();
  }
}
