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
  late DateTime _filtroDesde;
  late DateTime _filtroHasta;

  @override
  void initState() {
    super.initState();
    _filtroCategoria = widget.categoriaInicial;
    final mesActual = FiltroGastos.mesActual();
    _filtroDesde = mesActual.desde!;
    _filtroHasta = mesActual.hasta!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastosProvider>().cargar(
            filtro: FiltroGastos(
              categoria: _filtroCategoria,
              desde: _filtroDesde,
              hasta: _filtroHasta,
            ),
          );
      context.read<ProveedoresProvider>().cargar();
    });
  }

  void _aplicarFiltros() {
    context.read<GastosProvider>().cargar(
          filtro: FiltroGastos(
            proveedorId: _filtroProveedorId,
            categoria: _filtroCategoria,
            desde: _filtroDesde,
            hasta: _filtroHasta,
          ),
        );
  }

  bool get _esMesActual {
    final m = FiltroGastos.mesActual();
    return _filtroDesde.isAtSameMomentAs(m.desde!) && _filtroHasta.isAtSameMomentAs(m.hasta!);
  }

  bool get _esMesAnterior {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month - 1, 1);
    final h = DateTime(now.year, now.month, 0, 23, 59, 59);
    return _filtroDesde.isAtSameMomentAs(d) && _filtroHasta.isAtSameMomentAs(h);
  }

  bool get _esTodo => _filtroDesde.year == 2000 && _filtroDesde.month == 1 && _filtroDesde.day == 1;

  static String _fmtFecha(DateTime d) => DateFormat('d MMM', 'es').format(d);

  Future<void> _abrirPickerFecha() async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final safeDesde = _filtroDesde.isBefore(firstDate) ? firstDate : (_filtroDesde.isAfter(lastDate) ? lastDate : _filtroDesde);
    final safeHasta = _filtroHasta.isAfter(lastDate) ? lastDate : (_filtroHasta.isBefore(firstDate) ? firstDate : _filtroHasta);
    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: safeDesde, end: safeHasta),
      locale: const Locale('es'),
    );
    if (range != null && mounted) {
      setState(() {
        _filtroDesde = range.start;
        _filtroHasta = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      });
      _aplicarFiltros();
    }
  }

  Future<void> _confirmarEliminar(Gasto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Eliminar el gasto de "${gasto.proveedor?.nombre ?? (gasto.proveedorId != null ? 'proveedor #${gasto.proveedorId}' : 'gasto rápido')}" '
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
          // ── Período ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                _PeriodoChip(
                  label: 'Este mes',
                  selected: _esMesActual,
                  onTap: () {
                    final m = FiltroGastos.mesActual();
                    setState(() { _filtroDesde = m.desde!; _filtroHasta = m.hasta!; });
                    _aplicarFiltros();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodoChip(
                  label: 'Mes anterior',
                  selected: _esMesAnterior,
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _filtroDesde = DateTime(now.year, now.month - 1, 1);
                      _filtroHasta = DateTime(now.year, now.month, 0, 23, 59, 59);
                    });
                    _aplicarFiltros();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodoChip(
                  label: 'Todo',
                  selected: _esTodo,
                  onTap: () {
                    setState(() {
                      _filtroDesde = DateTime(2000);
                      _filtroHasta = DateTime(2100, 12, 31, 23, 59, 59);
                    });
                    _aplicarFiltros();
                  },
                ),
                const Spacer(),
                IconButton.outlined(
                  tooltip: _esTodo
                      ? 'Seleccionar rango'
                      : '${_fmtFecha(_filtroDesde)} – ${_fmtFecha(_filtroHasta)}',
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  onPressed: _abrirPickerFecha,
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
                                                  final nombre = d.nombre;
                                                  final prefix = d.cantidad > 1 ? '${cantidadStr(d.cantidad)} ' : '';
                                                  return Text(
                                                    '$prefix$nombre',
                                                    style: Theme.of(context).textTheme.bodyLarge,
                                                  );
                                                }),
                                                const SizedBox(height: 2),
                                                Text(
                                                  gasto.proveedor?.nombre ?? (gasto.proveedorId != null ? 'Proveedor #${gasto.proveedorId}' : 'Sin proveedor'),
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

class _PeriodoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodoChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
