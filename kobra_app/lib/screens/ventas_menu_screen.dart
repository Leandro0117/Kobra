import 'package:flutter/material.dart';
import '../widgets/menu_opciones.dart';
import 'clientes_screen.dart';
import 'productos_screen.dart';
import 'nueva_venta_screen.dart';
import 'ventas_screen.dart';

/// Opciones del apartado de Ventas. Se usa tanto desde el submenú de Ventas
/// (ADMIN) como directo en el Home (VENDEDOR, que solo tiene este apartado).
List<OpcionMenu> opcionesVentas(BuildContext context, bool esAdmin) {
  return [
    OpcionMenu(
      titulo: 'Nueva venta',
      icono: Icons.add_shopping_cart,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NuevaVentaScreen()),
      ),
    ),
    OpcionMenu(
      titulo: esAdmin ? 'Ventas' : 'Mis ventas',
      icono: Icons.receipt_long_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VentasScreen()),
      ),
    ),
    OpcionMenu(
      titulo: 'Clientes',
      icono: Icons.people_outline,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ClientesScreen()),
      ),
    ),
    OpcionMenu(
      titulo: 'Productos',
      icono: Icons.inventory_2_outlined,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductosScreen()),
      ),
    ),
  ];
}

class VentasMenuScreen extends StatelessWidget {
  const VentasMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MenuOpcionesGrid(opciones: opcionesVentas(context, true)),
      ),
    );
  }
}
