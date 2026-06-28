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
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

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
/// se verifica si hay un token guardado, login si no hay sesión, home si sí.
class _RaizApp extends StatelessWidget {
  const _RaizApp();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.verificandoSesion) {
      return const SplashScreen();
    }
    return authProvider.estaAutenticado ? const HomeScreen() : const LoginScreen();
  }
}
