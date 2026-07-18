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

Color _colorCategoria(CategoriaGasto cat) {
  switch (cat) {
    case CategoriaGasto.INSUMOS:
      return const Color(0xFF378ADD);
    case CategoriaGasto.EQUIPAMIENTO:
      return const Color(0xFFEF9F27);
    case CategoriaGasto.SERVICIOS:
      return const Color(0xFF639922);
    case CategoriaGasto.TRANSPORTE:
      return const Color(0xFF7B5EA7);
    case CategoriaGasto.OTRO:
      return const Color(0xFF888780);
  }
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

                final gastos = gastosProvider.gastos;

                // Resumen por día
                final resumenPorDia = <DateTime, ({int cantidad, double total})>{};
                for (final g in gastos) {
                  final dia = DateTime(g.fecha.year, g.fecha.month, g.fecha.day);
                  final prev = resumenPorDia[dia];
                  resumenPorDia[dia] = prev == null
                      ? (cantidad: 1, total: g.total)
                      : (cantidad: prev.cantidad + 1, total: prev.total + g.total);
                }

                final items = <Object>[];
                DateTime? diaActual;
                for (final gasto in gastos) {
                  final dia = DateTime(gasto.fecha.year, gasto.fecha.month, gasto.fecha.day);
                  if (diaActual == null || dia != diaActual) {
                    items.add(dia);
                    diaActual = dia;
                  }
                  items.add(gasto);
                }

                String cantidadStr(double c) =>
                    c == c.truncateToDouble() ? c.toInt().toString() : c.toString();

                return RefreshIndicator(
                  onRefresh: () => gastosProvider.cargar(),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      if (item is DateTime) {
                        final resumen = resumenPorDia[item]!;
                        final labelCantidad = resumen.cantidad == 1
                            ? '1 gasto'
                            : '${resumen.cantidad} gastos';
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            children: [
                              Text(
                                _etiquetaFecha(item),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$labelCantidad · ${formatPrecio(resumen.total)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final gasto = item as Gasto;
                      return Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 5, color: _colorCategoria(gasto.categoria)),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DetalleGastoScreen(gastoId: gasto.id),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  categoriaGastoLabel(gasto.categoria),
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: _colorCategoria(gasto.categoria),
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                ...gasto.detalles.map((d) {
                                                  final nombre = d.insumo?.nombre ?? 'Insumo #${d.insumoId}';
                                                  final prefix = d.cantidad > 1 ? '${cantidadStr(d.cantidad)} ' : '';
                                                  return Text(
                                                    '$prefix$nombre',
                                                    style: Theme.of(context).textTheme.bodyLarge,
                                                  );
                                                }),
                                                const SizedBox(height: 2),
                                                Text(
                                                  gasto.proveedor?.nombre ?? 'Proveedor #${gasto.proveedorId}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.outline,
                                                      ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                formatPrecio(gasto.total),
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              // IconButton(
                                              //   icon: const Icon(Icons.delete_outline),
                                              //   tooltip: 'Eliminar gasto',
                                              //   padding: EdgeInsets.zero,
                                              //   constraints: const BoxConstraints(),
                                              //   onPressed: () => _confirmarEliminar(gasto),
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
