import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import 'clientes_screen.dart';
import 'productos_screen.dart';
import 'nueva_venta_screen.dart';
import 'ventas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario!;
    final esAdmin = usuario.rol == Rol.ADMIN;

    final opciones = <_OpcionHome>[
      _OpcionHome(
        titulo: 'Nueva venta',
        icono: Icons.add_shopping_cart,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NuevaVentaScreen()),
        ),
      ),
      _OpcionHome(
        titulo: esAdmin ? 'Todas las ventas' : 'Mis ventas',
        icono: Icons.receipt_long,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VentasScreen()),
        ),
      ),
      _OpcionHome(
        titulo: 'Clientes',
        icono: Icons.people_outline,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClientesScreen()),
        ),
      ),
      _OpcionHome(
        titulo: 'Productos',
        icono: Icons.inventory_2_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductosScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kobra'),
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
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: opciones.map((o) => _TarjetaOpcion(opcion: o)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionHome {
  final String titulo;
  final IconData icono;
  final VoidCallback onTap;

  _OpcionHome({required this.titulo, required this.icono, required this.onTap});
}

class _TarjetaOpcion extends StatelessWidget {
  final _OpcionHome opcion;

  const _TarjetaOpcion({required this.opcion});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: opcion.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(opcion.icono, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(opcion.titulo, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
