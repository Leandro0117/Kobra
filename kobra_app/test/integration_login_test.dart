import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kobra_app/services/auth_service.dart';
import 'package:kobra_app/services/clientes_service.dart';
import 'package:kobra_app/services/productos_service.dart';
import 'package:kobra_app/services/api_client.dart';
import 'package:kobra_app/models/usuario.dart';

/// Prueba manual de integración contra el backend real corriendo en
/// localhost:3000. No se ejecuta en CI; sirve para verificar a mano que la
/// capa de servicios de la app habla correctamente con la API.
///
/// No usa TokenStorage (flutter_secure_storage) porque su plugin nativo no
/// está disponible en el entorno de "flutter test"; en su lugar inyecta el
/// header de autorización directo en el cliente Dio, solo para esta prueba.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // TestWidgetsFlutterBinding intercepta HttpClient y devuelve 400 por
  // defecto; se desactiva para permitir la llamada de red real al backend.
  HttpOverrides.global = null;

  test('login real contra el backend y listados básicos', () async {
    final auth = AuthService();
    final resultado = await auth.login('admin@kobra.com', 'admin123');

    expect(resultado.usuario.email, 'admin@kobra.com');
    expect(resultado.usuario.rol, Rol.ADMIN);
    expect(resultado.accessToken, isNotEmpty);

    ApiClient.instance.options.headers['Authorization'] = 'Bearer ${resultado.accessToken}';

    final clientes = await ClientesService().listar();
    expect(clientes, isNotEmpty);

    final productos = await ProductosService().listar();
    expect(productos, isNotEmpty);
  });
}
