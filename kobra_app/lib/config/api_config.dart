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
