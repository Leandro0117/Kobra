/// Configuración central de la URL del backend de Kobra.
///
/// MIENTRAS DESARROLLAS EN LOCAL:
///   - Si corres la app en un emulador Android, usa 10.0.2.2 en vez de localhost
///     (10.0.2.2 es la forma en que el emulador Android accede al host).
///   - Si corres en Windows/Web/iOS simulator, localhost funciona directo.
///
/// CUANDO DESPLIEGUES EN RENDER:
///   - Reemplaza el valor de [baseUrl] por la URL pública de Render, por ejemplo:
///     'https://kobra-backend.onrender.com'
///   - Vuelve a compilar la app (o hacer hot-restart) para que tome el cambio.
class ApiConfig {
  // static const String baseUrl = 'http://localhost:3000'; // Local
  // static const String baseUrl = 'http://192.168.128.8:3000'; // Local
  static const String baseUrl = 'https://kobra-6y6c.onrender.com'; // Render

  /// Render free tier "duerme" el servicio tras inactividad. La primera
  /// petición tras el sueño puede tardar bastante en responder.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Si una petición tarda más que esto, la UI muestra el mensaje de
  /// "el servidor puede estar despertando" en lugar de un spinner genérico.
  static const Duration umbralServidorDormido = Duration(seconds: 4);
}
