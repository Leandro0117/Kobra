import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../models/venta.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/ventas_provider.dart';
import '../services/ventas_service.dart';
import '../widgets/estado_carga.dart';
import 'detalle_venta_screen.dart';

/// Pantalla de listado de ventas, reutilizada tanto para "en curso" como
/// para "historial" — [estadosPermitidos] define qué subconjunto de
/// estados se muestra (el filtro se aplica en el cliente, no en el backend).
class VentasScreen extends StatefulWidget {
  final String titulo;
  final List<EstadoVenta> estadosPermitidos;

  const VentasScreen({super.key, required this.titulo, required this.estadosPermitidos});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  EstadoVenta? _filtroEstado;
  int? _filtroClienteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentasProvider>().cargar();
      context.read<ClientesProvider>().cargar();
    });
  }

  void _aplicarFiltroCliente() {
    context.read<VentasProvider>().cargar(filtro: FiltroVentas(clienteId: _filtroClienteId));
  }

  Future<void> _confirmarEliminar(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text(
          '¿Eliminar la venta de "${venta.cliente?.nombre ?? 'cliente #${venta.clienteId}'}" '
          'por \$${venta.total.toStringAsFixed(2)}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final ventasProvider = context.read<VentasProvider>();
      final ok = await ventasProvider.eliminar(venta.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ventasProvider.error ?? 'No se pudo eliminar la venta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = context.watch<VentasProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;

    final ventasDelGrupo = ventasProvider.ventas
        .where((v) => widget.estadosPermitidos.contains(v.estado))
        .where((v) => _filtroEstado == null || v.estado == _filtroEstado)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          if (esAdmin)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<EstadoVenta?>(
                      initialValue: _filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...widget.estadosPermitidos.map(
                          (e) => DropdownMenuItem(value: e, child: Text(estadoLabel(e))),
                        ),
                      ],
                      onChanged: (e) => setState(() => _filtroEstado = e),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _filtroClienteId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...clientesProvider.clientes.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                        ),
                      ],
                      onChanged: (id) {
                        setState(() => _filtroClienteId = id);
                        _aplicarFiltroCliente();
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (ventasProvider.cargando) {
                  return EstadoCargando(avisoServidorLento: ventasProvider.avisoServidorLento);
                }
                if (ventasProvider.error != null) {
                  return EstadoError(
                    mensaje: ventasProvider.error!,
                    onReintentar: () => ventasProvider.cargar(),
                  );
                }
                if (ventasDelGrupo.isEmpty) {
                  return const Center(child: Text('No hay ventas para mostrar aquí.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ventasProvider.cargar(),
                  child: ListView.separated(
                    itemCount: ventasDelGrupo.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final venta = ventasDelGrupo[index];
                      return ListTile(
                        title: Text(venta.cliente?.nombre ?? 'Cliente #${venta.clienteId}'),
                        subtitle: Text(
                          esAdmin
                              ? '${venta.vendedor?.nombre ?? ''} · ${estadoLabel(venta.estado)}'
                              : estadoLabel(venta.estado),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${venta.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Eliminar venta',
                              onPressed: () => _confirmarEliminar(venta),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetalleVentaScreen(ventaId: venta.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
