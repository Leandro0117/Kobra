import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sobre flutter_secure_storage para guardar el JWT y los datos
/// básicos del usuario logueado (sin base de datos local: solo credenciales
/// de sesión, todo lo demás siempre se consulta al backend).
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );
  static const _keyToken = 'kobra_access_token';
  static const _keyUsuarioJson = 'kobra_usuario';

  static Future<void> guardarSesion(String token, String usuarioJson) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUsuarioJson, value: usuarioJson);
  }

  static Future<String?> leerToken() => _storage.read(key: _keyToken);

  static Future<String?> leerUsuarioJson() => _storage.read(key: _keyUsuarioJson);

  static Future<void> limpiarSesion() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsuarioJson);
  }
}
