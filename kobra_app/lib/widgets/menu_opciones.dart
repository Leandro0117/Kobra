import 'package:flutter/material.dart';

class OpcionMenu {
  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final VoidCallback onTap;

  OpcionMenu({required this.titulo, this.subtitulo, required this.icono, required this.onTap});
}

/// Tarjeta hero de ancho completo para la acción principal de un submenú.
class HeroOpcionMenu extends StatelessWidget {
  final OpcionMenu opcion;

  const HeroOpcionMenu({super.key, required this.opcion});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: color,
      child: InkWell(
        onTap: opcion.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(opcion.icono, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opcion.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (opcion.subtitulo != null)
                    Text(
                      opcion.subtitulo!,
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
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
