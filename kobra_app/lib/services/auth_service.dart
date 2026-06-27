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
}
