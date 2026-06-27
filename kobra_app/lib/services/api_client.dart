import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Cliente HTTP centralizado. Agrega el JWT a cada petición y traduce los
/// errores de Dio a [ApiException] con mensajes ya listos para mostrar.
///
/// Callback opcional que se dispara cuando el backend responde 401
/// (token vencido o inválido): lo usa AuthProvider para cerrar sesión.
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
      final token = await TokenStorage.leerToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Si no se puede leer el almacenamiento seguro, la petición sigue sin
      // token: el backend la rechazará con 401 si la ruta lo requiere, en
      // vez de dejarla colgada indefinidamente.
    }
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
    String mensaje = 'Ocurrió un error inesperado. Intenta de nuevo.';

    if (data is Map && data['message'] != null) {
      final m = data['message'];
      mensaje = m is List ? m.join(', ') : m.toString();
    } else if (statusCode == 401) {
      mensaje = 'Tu sesión expiró. Vuelve a iniciar sesión.';
    } else if (statusCode == 403) {
      mensaje = 'No tienes permiso para hacer esto.';
    } else if (statusCode == 404) {
      mensaje = 'No se encontró el recurso solicitado.';
    }

    return ApiException(mensaje, statusCode: statusCode);
  }
}
