import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Cliente HTTP centralizado. Agrega el JWT a cada petición y traduce los
/// errores de Dio a [ApiException] con mensajes ya listos para mostrar.
class ApiClient {
  static void Function()? onUnauthorized;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );

  static Dio get instance => _dio;

  static Future<void> _agregarToken(RequestOptions options) async {
    try {
      final token = await TokenStorage.leerToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
  }

  static bool _interceptorInstalado = false;

  static void _asegurarInterceptor() {
    if (_interceptorInstalado) return;
    _interceptorInstalado = true;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _agregarToken(options);
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    _asegurarInterceptor();
    return _ejecutar(() => _dio.get<T>(path, queryParameters: query));
  }

  static Future<Response<T>> post<T>(String path, {Object? data}) {
    _asegurarInterceptor();
    return _ejecutar(() => _dio.post<T>(path, data: data));
  }

  static Future<Response<T>> patch<T>(String path, {Object? data}) {
    _asegurarInterceptor();
    return _ejecutar(() => _dio.patch<T>(path, data: data));
  }

  static Future<Response<T>> delete<T>(String path) {
    _asegurarInterceptor();
    return _ejecutar(() => _dio.delete<T>(path));
  }

  static Future<Response<T>> _ejecutar<T>(Future<Response<T>> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw _traducirError(e);
    }
  }

  static ApiException _traducirError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'No se pudo conectar con el servidor. Si lleva un rato inactivo, '
        'puede tardar unos segundos en despertar. Intenta de nuevo en breve.',
        esTimeout: true,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        'No hay conexión con el servidor. Revisa tu internet o vuelve a intentar.',
      );
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Extraer el mensaje del body si el backend lo envía.
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      final texto = m is List ? m.join(', ') : m.toString();
      return ApiException(texto, statusCode: statusCode);
    }

    // Sin body útil: usar mensaje según código HTTP.
    final mensaje = switch (statusCode) {
      401 => 'No autorizado. Verifica tus credenciales o vuelve a iniciar sesión.',
      403 => 'No tienes permiso para realizar esta acción.',
      404 => 'No se encontró el recurso solicitado.',
      409 => 'Ya existe un registro con esos datos.',
      422 => 'Los datos enviados no son válidos.',
      500 => 'Error interno del servidor. Intenta de nuevo más tarde.',
      null => 'No se recibió respuesta del servidor. Revisa tu conexión.',
      _ => 'Error del servidor ($statusCode). Intenta de nuevo.',
    };

    return ApiException(mensaje, statusCode: statusCode);
  }
}
