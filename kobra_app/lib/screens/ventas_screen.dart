import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../models/venta.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/ventas_provider.dart';
import '../services/ventas_service.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';
import 'detalle_venta_screen.dart';

String _etiquetaFecha(DateTime fecha) {
  final hoy = DateTime.now();
  final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
  final diff = soloHoy.difference(soloFecha).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return DateFormat('d MMMM', 'es').format(fecha);
}

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
          'por ${formatPrecio(venta.total)}? Esta acción no se puede deshacer.',
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

    // Construir lista plana: DateTime (cabecera) o Venta
    final items = <Object>[];
    DateTime? diaActual;
    for (final venta in ventas) {
      final dia = DateTime(venta.fecha.year, venta.fecha.month, venta.fecha.day);
      if (diaActual == null || dia != diaActual) {
        items.add(dia);
        diaActual = dia;
      }
      items.add(venta);
    }

    return RefreshIndicator(
      onRefresh: () => ventasProvider.cargar(forzar: true),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is DateTime) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                _etiquetaFecha(item),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            );
          }
          final venta = item as Venta;
          return Column(
            children: [
              ListTile(
                title: Text(venta.cliente?.nombre ?? 'Cliente #${venta.clienteId}'),
                subtitle: Text(
                  esAdmin
                      ? '${venta.vendedor?.nombre ?? ''} · ${estadoLabel(venta.estado)}'
                      : estadoLabel(venta.estado),
                ),
                trailing: SizedBox(
                  width: 110,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          formatPrecio(venta.total),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _confirmarEliminar(venta),
                        child: const Icon(Icons.delete_outline, size: 18),
                      ),
                    ],
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DetalleVentaScreen(ventaId: venta.id)),
                ),
              ),
              const Divider(height: 1),
            ],
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
                      key: ValueKey(_filtroEstado),
                      initialValue: _filtroEstado,
                      isExpanded: true,
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
                      initialValue: _filtroClienteId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos')),
                        ...clientesProvider.clientes.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                          ),
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
