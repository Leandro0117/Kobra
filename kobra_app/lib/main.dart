import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/productos_provider.dart';
import 'providers/ventas_provider.dart';
import 'providers/estadisticas_provider.dart';
import 'providers/proveedores_provider.dart';
import 'providers/insumos_provider.dart';
import 'providers/gastos_provider.dart';
import 'providers/finanzas_provider.dart';
import 'providers/negocio_provider.dart';
import 'models/usuario.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/registro_negocio_screen.dart';

void main() {
  runApp(const KobraApp());
}

class KobraApp extends StatelessWidget {
  const KobraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ChangeNotifierProvider(create: (_) => ProductosProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => EstadisticasProvider()),
        ChangeNotifierProvider(create: (_) => ProveedoresProvider()),
        ChangeNotifierProvider(create: (_) => InsumosProvider()),
        ChangeNotifierProvider(create: (_) => GastosProvider()),
        ChangeNotifierProvider(create: (_) => FinanzasProvider()),
        ChangeNotifierProvider(create: (_) => NegocioProvider()),
      ],
      child: MaterialApp(
        title: 'Kobra',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const _RaizApp(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de sesión: splash mientras
/// se verifica si hay un token guardado, login si no hay sesión. Si hay
/// sesión y el usuario es ADMIN, primero se verifica que el negocio esté
/// registrado (paso obligatorio una sola vez); si no, se pide antes de
/// entrar a Home.
class _RaizApp extends StatefulWidget {
  const _RaizApp();

  @override
  State<_RaizApp> createState() => _RaizAppState();
}

class _RaizAppState extends State<_RaizApp> {
  bool _estabaAutenticado = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final negocioProvider = context.watch<NegocioProvider>();

    if (authProvider.verificandoSesion) {
      return const SplashScreen();
    }

    if (!authProvider.estaAutenticado) {
      _estabaAutenticado = false;
      return const LoginScreen();
    }

    if (!_estabaAutenticado) {
      // Recién se autenticó (login o sesión restaurada): reinicia el estado
      // del negocio para que se vuelva a verificar contra el backend.
      _estabaAutenticado = true;
      negocioProvider.reiniciar();
    }

    final esAdmin = authProvider.usuario!.rol == Rol.ADMIN;
    if (!esAdmin) {
      return const HomeScreen();
    }

    if (!negocioProvider.verificado && !negocioProvider.cargando) {
      // No se puede llamar directo: cargar() notifica de inmediato y eso
      // dispararía un rebuild en medio de este build.
      Future.microtask(negocioProvider.cargar);
    }
    if (negocioProvider.cargando && !negocioProvider.verificado) {
      return const SplashScreen();
    }
    if (negocioProvider.negocio == null) {
      return const RegistroNegocioScreen();
    }
    return const HomeScreen();
  }
}
