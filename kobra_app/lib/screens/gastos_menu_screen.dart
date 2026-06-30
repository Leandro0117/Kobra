import 'package:flutter/material.dart';
import '../widgets/menu_opciones.dart';
import 'proveedores_screen.dart';
import 'insumos_screen.dart';
import 'nuevo_gasto_screen.dart';
import 'gastos_screen.dart';

/// Apartado de Gastos: compra de insumos, proveedores y egresos en general.
/// Exclusivo de ADMIN.
class GastosMenuScreen extends StatelessWidget {
  const GastosMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = <OpcionMenu>[
      OpcionMenu(
        titulo: 'Nuevo gasto',
        subtitulo: 'Registrar egreso',
        icono: Icons.add_card_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NuevoGastoScreen()),
        ),
      ),
      OpcionMenu(
        titulo: 'Historial de gastos',
        icono: Icons.receipt_long_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GastosScreen()),
        ),
      ),
      OpcionMenu(
        titulo: 'Proveedores',
        icono: Icons.local_shipping_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
        ),
      ),
      OpcionMenu(
        titulo: 'Insumos',
        icono: Icons.inventory_outlined,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InsumosScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HeroOpcionMenu(opcion: opciones.first),
            const SizedBox(height: 16),
            Expanded(child: MenuOpcionesGrid(opciones: opciones.skip(1).toList())),
          ],
        ),
      ),
    );
  }
}
