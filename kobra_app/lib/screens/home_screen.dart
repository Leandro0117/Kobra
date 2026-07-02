import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../widgets/kobra_logo.dart';
import '../widgets/menu_opciones.dart';
import 'ventas_menu_screen.dart';
import 'gastos_menu_screen.dart';
import 'finanzas_screen.dart';
import 'vendedores_screen.dart';
import 'registro_negocio_screen.dart';
import 'ajustes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario!;
    final esAdmin = usuario.rol == Rol.ADMIN;

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
              titulo: 'Resumen',
              icono: Icons.dashboard_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinanzasScreen()),
              ),
            ),
            OpcionMenu(
              titulo: 'Vendedores',
              icono: Icons.people_outline,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VendedoresScreen()),
              ),
            ),
          ]
        : null;

    final opcionesVendedor = esAdmin ? null : opcionesVentas(context, false);

    return Scaffold(
      appBar: AppBar(
        title: const KobraLogo(height: 28),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Mi cuenta',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _UserDrawer(
        usuario: usuario,
        esAdmin: esAdmin,
        authProvider: authProvider,
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
            if (!esAdmin) ...[
              HeroOpcionMenu(opcion: opcionesVendedor!.first),
              const SizedBox(height: 16),
              Expanded(child: MenuOpcionesGrid(opciones: opcionesVendedor.skip(1).toList())),
            ] else
              Expanded(child: MenuOpcionesGrid(opciones: opciones!)),
          ],
        ),
      ),
    );
  }
}

// ── Drawer de usuario ─────────────────────────────────────────────────────────

class _UserDrawer extends StatelessWidget {
  final Usuario usuario;
  final bool esAdmin;
  final AuthProvider authProvider;

  const _UserDrawer({
    required this.usuario,
    required this.esAdmin,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabecera ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Text(
                      usuario.nombre[0].toUpperCase(),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nombre,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          usuario.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          esAdmin ? 'Administrador' : 'Vendedor',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Opciones ──
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AjustesScreen()),
                );
              },
            ),
            if (esAdmin)
              ListTile(
                leading: const Icon(Icons.store_outlined),
                title: const Text('Mi negocio'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegistroNegocioScreen(esEdicion: true),
                    ),
                  );
                },
              ),

            const Spacer(),
            const Divider(height: 1),

            // ── Cerrar sesión ──
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que querés cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) authProvider.cerrarSesion();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
