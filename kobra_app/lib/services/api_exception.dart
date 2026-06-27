/// Excepción genérica para errores de la API, con un mensaje ya pensado
/// para mostrarse directo en la UI.
class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;
  final bool esTimeout;

  ApiException(this.mensaje, {this.statusCode, this.esTimeout = false});

  bool get esNoAutorizado => statusCode == 401;

  @override
  String toString() => mensaje;
}
