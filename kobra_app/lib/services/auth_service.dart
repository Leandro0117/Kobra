import 'api_client.dart';
import '../models/usuario.dart';

class LoginResultado {
  final String accessToken;
  final Usuario usuario;

  LoginResultado({required this.accessToken, required this.usuario});
}

class AuthService {
  Future<LoginResultado> login(String email, String password) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    return LoginResultado(
      accessToken: data['accessToken'] as String,
      usuario: Usuario.fromJson(data['usuario'] as Map<String, dynamic>),
    );
  }

  Future<List<Map<String, dynamic>>> listarVendedores() async {
    final response = await ApiClient.get<List<dynamic>>('/auth/vendedores');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> actualizarVendedor({
    required int id,
    String? nombre,
    String? email,
    String? password,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    await ApiClient.patch<Map<String, dynamic>>('/auth/vendedores/$id', data: data);
  }

  Future<void> crearVendedor({
    required String nombre,
    required String email,
    required String password,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/auth/vendedores',
      data: {'nombre': nombre, 'email': email, 'password': password},
    );
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required String negocioNombre,
    required String negocioMoneda,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'nombre': nombre,
        'email': email,
        'password': password,
        'negocio': {'nombre': negocioNombre, 'moneda': negocioMoneda},
      },
    );
  }
}
