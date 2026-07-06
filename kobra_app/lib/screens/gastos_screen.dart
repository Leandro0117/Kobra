import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../models/categoria_gasto.dart';
import '../providers/proveedores_provider.dart';
import '../providers/gastos_provider.dart';
import '../services/gastos_service.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';
import 'detalle_gasto_screen.dart';

String _etiquetaFecha(DateTime fecha) {
  final hoy = DateTime.now();
  final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
  final diff = soloHoy.difference(soloFecha).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return DateFormat('d MMMM', 'es').format(fecha);
}

class GastosScreen extends StatefulWidget {
  final CategoriaGasto? categoriaInicial;

  const GastosScreen({super.key, this.categoriaInicial});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  late CategoriaGasto? _filtroCategoria;
  int? _filtroProveedorId;

  @override
  void initState() {
    super.initState();
    _filtroCategoria = widget.categoriaInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastosProvider>().cargar(
            filtro: FiltroGastos(categoria: _filtroCategoria),
          );
      context.read<ProveedoresProvider>().cargar();
    });
  }

  void _aplicarFiltros() {
    context.read<GastosProvider>().cargar(
          filtro: FiltroGastos(proveedorId: _filtroProveedorId, categoria: _filtroCategoria),
        );
  }

  Future<void> _confirmarEliminar(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Eliminar el gasto de "${gasto.proveedor?.nombre ?? 'proveedor #${gasto.proveedorId}'}" '
          'por ${formatPrecio(gasto.total)}? Esta acción no se puede deshacer.',
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
      final gastosProvider = context.read<GastosProvider>();
      final ok = await gastosProvider.eliminar(gasto.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gastosProvider.error ?? 'No se pudo eliminar el gasto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gastosProvider = context.watch<GastosProvider>();
    final proveedoresProvider = context.watch<ProveedoresProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de gastos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CategoriaGasto?>(
                    initialValue: _filtroCategoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...CategoriaGasto.values.map(
                        (c) => DropdownMenuItem(value: c, child: Text(categoriaGastoLabel(c))),
                      ),
                    ],
                    onChanged: (c) {
                      setState(() => _filtroCategoria = c);
                      _aplicarFiltros();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _filtroProveedorId,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...proveedoresProvider.proveedores.map(
                        (p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)),
                      ),
                    ],
                    onChanged: (id) {
                      setState(() => _filtroProveedorId = id);
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
                if (gastosProvider.cargando) {
                  return EstadoCargando(avisoServidorLento: gastosProvider.avisoServidorLento);
                }
                if (gastosProvider.error != null) {
                  return EstadoError(
                    mensaje: gastosProvider.error!,
                    onReintentar: () => gastosProvider.cargar(),
                  );
                }
                if (gastosProvider.gastos.isEmpty) {
                  return const Center(child: Text('No hay gastos registrados todavía.'));
                }

                // Construir lista con encabezados de fecha
                final items = <Object>[];
                DateTime? diaActual;
                for (final gasto in gastosProvider.gastos) {
                  final dia = DateTime(gasto.fecha.year, gasto.fecha.month, gasto.fecha.day);
                  if (diaActual == null || dia != diaActual) {
                    items.add(dia);
                    diaActual = dia;
                  }
                  items.add(gasto);
                }

                return RefreshIndicator(
                  onRefresh: () => gastosProvider.cargar(),
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

                      final gasto = item as Gasto;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(gasto.proveedor?.nombre ?? 'Proveedor #${gasto.proveedorId}'),
                            subtitle: Text(categoriaGastoLabel(gasto.categoria)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatPrecio(gasto.total),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Eliminar gasto',
                                  onPressed: () => _confirmarEliminar(gasto),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetalleGastoScreen(gastoId: gasto.id),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
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
