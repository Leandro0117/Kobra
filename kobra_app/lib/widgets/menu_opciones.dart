import 'package:flutter/material.dart';

class OpcionMenu {
  final String titulo;
  final IconData icono;
  final VoidCallback onTap;

  OpcionMenu({required this.titulo, required this.icono, required this.onTap});
}

/// Grid de tarjetas reutilizado por Home y por los submenús de Ventas/Gastos.
class MenuOpcionesGrid extends StatelessWidget {
  final List<OpcionMenu> opciones;

  const MenuOpcionesGrid({super.key, required this.opciones});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: opciones.map((o) => _TarjetaOpcionMenu(opcion: o)).toList(),
    );
  }
}

class _TarjetaOpcionMenu extends StatelessWidget {
  final OpcionMenu opcion;

  const _TarjetaOpcionMenu({required this.opcion});

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
