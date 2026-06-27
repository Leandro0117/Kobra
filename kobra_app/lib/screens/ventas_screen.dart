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

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

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

  void _aplicarFiltros() {
    context.read<VentasProvider>().cargar(
          filtro: FiltroVentas(estado: _filtroEstado, clienteId: _filtroClienteId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = context.watch<VentasProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;

    return Scaffold(
      appBar: AppBar(title: Text(esAdmin ? 'Todas las ventas' : 'Mis ventas')),
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
                        ...EstadoVenta.values.map(
                          (e) => DropdownMenuItem(value: e, child: Text(estadoLabel(e))),
                        ),
                      ],
                      onChanged: (e) {
                        setState(() => _filtroEstado = e);
                        _aplicarFiltros();
                      },
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
                        _aplicarFiltros();
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
                if (ventasProvider.ventas.isEmpty) {
                  return const Center(child: Text('No hay ventas registradas todavía.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ventasProvider.cargar(),
                  child: ListView.separated(
                    itemCount: ventasProvider.ventas.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final venta = ventasProvider.ventas[index];
                      return ListTile(
                        title: Text(venta.cliente?.nombre ?? 'Cliente #${venta.clienteId}'),
                        subtitle: Text(
                          esAdmin
                              ? '${venta.vendedor?.nombre ?? ''} · ${estadoLabel(venta.estado)}'
                              : estadoLabel(venta.estado),
                        ),
                        trailing: Text(
                          '\$${venta.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
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
