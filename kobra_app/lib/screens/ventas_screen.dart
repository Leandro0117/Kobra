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

class _VentasScreenState extends State<VentasScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  EstadoVenta? _filtroEstado;
  int? _filtroClienteId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _filtroEstado = null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentasProvider>().cargar();
      context.read<ClientesProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EstadoVenta> get _estadosActuales =>
      _tabController.index == 0 ? estadosEnCurso : estadosHistorial;

  void _aplicarFiltroCliente(int? clienteId) {
    setState(() => _filtroClienteId = clienteId);
    context.read<VentasProvider>().cargar(filtro: FiltroVentas(clienteId: clienteId));
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

  Widget _buildLista(
    BuildContext context,
    VentasProvider ventasProvider,
    ClientesProvider clientesProvider,
    bool esAdmin,
    List<EstadoVenta> estados,
  ) {
    if (ventasProvider.cargando) {
      return EstadoCargando(avisoServidorLento: ventasProvider.avisoServidorLento);
    }
    if (ventasProvider.error != null) {
      return EstadoError(
        mensaje: ventasProvider.error!,
        onReintentar: () => ventasProvider.cargar(),
      );
    }

    final ventas = ventasProvider.ventas
        .where((v) => estados.contains(v.estado))
        .where((v) => _filtroEstado == null || v.estado == _filtroEstado)
        .toList();

    if (ventas.isEmpty) {
      return const Center(child: Text('No hay ventas para mostrar aquí.'));
    }

    return RefreshIndicator(
      onRefresh: () => ventasProvider.cargar(forzar: true),
      child: ListView.separated(
        itemCount: ventas.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final venta = ventas[index];
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
              MaterialPageRoute(builder: (_) => DetalleVentaScreen(ventaId: venta.id)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventasProvider = context.watch<VentasProvider>();
    final clientesProvider = context.watch<ClientesProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;
    final titulo = esAdmin ? 'Ventas' : 'Mis ventas';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En curso'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (esAdmin)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<EstadoVenta?>(
                      value: _filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ..._estadosActuales.map(
                          (e) => DropdownMenuItem(value: e, child: Text(estadoLabel(e))),
                        ),
                      ],
                      onChanged: (e) => setState(() => _filtroEstado = e),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _filtroClienteId,
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
                      onChanged: (id) => _aplicarFiltroCliente(id),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLista(context, ventasProvider, clientesProvider, esAdmin, estadosEnCurso),
                _buildLista(context, ventasProvider, clientesProvider, esAdmin, estadosHistorial),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
