import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../widgets/kobra_logo.dart';
import '../widgets/menu_opciones.dart';
import 'ventas_menu_screen.dart';
import 'gastos_menu_screen.dart';
import 'finanzas_screen.dart';
import 'estadisticas_screen.dart';
import 'registro_negocio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario!;
    final esAdmin = usuario.rol == Rol.ADMIN;

    // VENDEDOR solo tiene el apartado de ventas, así que va directo a esas
    // opciones sin pasar por un selector de secciones. ADMIN ve los tres
    // apartados del negocio (Ventas / Gastos / Finanzas).
    final opciones = esAdmin
        ? <OpcionMenu>[
            OpcionMenu(
              titulo: 'Ventas',
              icono: Icons.point_of_sale,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VentasMenuScreen()),
              ),
            ),
            OpcionMenu(
              titulo: 'Gastos',
              icono: Icons.shopping_cart_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GastosMenuScreen()),
              ),
            ),
            OpcionMenu(
              titulo: 'Finanzas',
              icono: Icons.account_balance_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinanzasScreen()),
              ),
            ),
            OpcionMenu(
              titulo: 'Estadísticas',
              icono: Icons.bar_chart_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EstadisticasScreen()),
              ),
            ),
            OpcionMenu(
              titulo: 'Configuración',
              icono: Icons.settings_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RegistroNegocioScreen(esEdicion: true),
                ),
              ),
            ),
          ]
        : opcionesVentas(context, false);

    return Scaffold(
      appBar: AppBar(
        title: const KobraLogo(height: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => authProvider.cerrarSesion(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${usuario.nombre}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              esAdmin ? 'Administrador' : 'Vendedor',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(child: MenuOpcionesGrid(opciones: opciones)),
          ],
        ),
      ),
    );
  }
}
