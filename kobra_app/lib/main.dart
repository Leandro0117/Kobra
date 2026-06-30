import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
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
      if (_estabaAutenticado) {
        // Sesión cerrada: reinicia negocio para re-verificar en el próximo login.
        _estabaAutenticado = false;
        Future.microtask(negocioProvider.reiniciar);
      }
      return const LoginScreen();
    }

    if (!_estabaAutenticado) {
      // Recién autenticado: programa el reinicio y la carga del negocio fuera
      // del build para evitar el frame fantasma entre reiniciar() y cargar().
      _estabaAutenticado = true;
      Future.microtask(() {
        negocioProvider.reiniciar();
        negocioProvider.cargar();
      });
    }

    final esAdmin = authProvider.usuario!.rol == Rol.ADMIN;
    if (!esAdmin) {
      return const HomeScreen();
    }

    // Mientras negocio no esté verificado (cargando o aún no arrancó), splash.
    if (!negocioProvider.verificado) {
      return const SplashScreen();
    }
    // Solo pedir registro si el servidor confirmó que no existe (sin error).
    // Si cargar() falló (red, auth, etc.) el error no es null: se va al home
    // y la app funciona con normalidad.
    if (negocioProvider.negocio == null && negocioProvider.error == null) {
      return const RegistroNegocioScreen();
    }
    return const HomeScreen();
  }
}
