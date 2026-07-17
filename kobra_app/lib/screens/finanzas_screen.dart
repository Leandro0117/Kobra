import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria_gasto.dart';
import '../models/cliente.dart';
import '../models/estadisticas.dart';
import '../models/finanzas.dart';
import '../providers/estadisticas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';
import 'detalle_cliente_screen.dart';
import 'gastos_screen.dart';
import 'ventas_screen.dart';

const _coloresPie = [
  Color(0xFF6366F1),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
];

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstadisticasProvider>().cargar();
    });
  }

  void _cambiarPeriodo(PeriodoEstadisticas periodo) {
    context.read<EstadisticasProvider>().cargar(periodo: periodo);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstadisticasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<PeriodoEstadisticas>(
              initialValue: provider.periodo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PeriodoEstadisticas.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(periodoLabel(p)),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p != null) _cambiarPeriodo(p);
              },
            ),
          ),
          Expanded(child: _buildContenido(context, provider)),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context, EstadisticasProvider provider) {
    if (provider.cargando) {
      return EstadoCargando(avisoServidorLento: provider.avisoServidorLento);
    }
    if (provider.error != null) {
      return EstadoError(
        mensaje: provider.error!,
        onReintentar: () => _cambiarPeriodo(provider.periodo),
      );
    }

    final resumen = provider.resumen;
    if (resumen == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => provider.cargar(forzar: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(finanzas: resumen.finanzas),
          const SizedBox(height: 20),
          _SeccionVentas(estadisticas: resumen.estadisticas),
          if (resumen.estadisticas.topVariantes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SeccionVariantes(variantes: resumen.estadisticas.topVariantes),
          ],
          if (resumen.estadisticas.topClientes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SeccionClientes(clientes: resumen.estadisticas.topClientes),
          ],
          if (resumen.finanzas.mediosPago.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SeccionMediosPago(mediosPago: resumen.finanzas.mediosPago),
          ],
          if (resumen.finanzas.egresosPorCategoria.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SeccionEgresos(
              categorias: resumen.finanzas.egresosPorCategoria,
              egresosPorInsumo: resumen.finanzas.egresosPorInsumo,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Balance (protagonista) ────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final ResumenFinanzas finanzas;
  const _BalanceCard({required this.finanzas});

  @override
  Widget build(BuildContext context) {
    final esGanancia = finanzas.balance >= 0;
    final colorBalance = esGanancia
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            Text(
              'Balance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatPrecio(finanzas.balance),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: colorBalance,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: colorBalance.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                esGanancia ? 'Ganancia' : 'Pérdida',
                style: TextStyle(
                  color: colorBalance,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _FilaBalance(
              label: 'Ingresos',
              valor: formatPrecio(finanzas.totalCobrado),
              color: const Color(0xFF16A34A),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const VentasScreen())),
            ),
            const SizedBox(height: 10),
            _FilaBalance(
              label: 'Egresos',
              valor: formatPrecio(finanzas.totalEgresos),
              color: Theme.of(context).colorScheme.error,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GastosScreen())),
            ),
            const SizedBox(height: 10),
            _FilaBalance(
              label: 'Por cobrar',
              valor: formatPrecio(finanzas.porCobrar),
              color: const Color(0xFFD97706),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const VentasScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaBalance extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final VoidCallback? onTap;

  const _FilaBalance({
    required this.label,
    required this.valor,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

// ── Sección ventas ────────────────────────────────────────────────────────────

class _SeccionVentas extends StatelessWidget {
  final ResumenEstadisticas estadisticas;
  const _SeccionVentas({required this.estadisticas});

  @override
  Widget build(BuildContext context) {
    final promedio = estadisticas.totalVentas > 0
        ? estadisticas.totalFacturado / estadisticas.totalVentas
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ventas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Número de ventas',
                valor: estadisticas.totalVentas.toString(),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const VentasScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Promedio por venta',
                valor: formatPrecio(promedio),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricCard(
          label: 'Total facturado',
          valor: formatPrecio(estadisticas.totalFacturado),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const VentasScreen())),
        ),
        if (estadisticas.ventasPorDia.length >= 2) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresos por día',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GraficoLinea(datos: estadisticas.ventasPorDia),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sección variantes ─────────────────────────────────────────────────────────

class _SeccionVariantes extends StatelessWidget {
  final List<ResumenVariante> variantes;
  const _SeccionVariantes({required this.variantes});

  @override
  Widget build(BuildContext context) {
    final maxCantidad = variantes
        .map((v) => v.cantidadVendida)
        .reduce(math.max);
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variantes más vendidas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              children: variantes
                  .map(
                    (v) => _BarraRanking(
                      titulo: v.nombre,
                      subtitulo:
                          '${v.producto} · ${formatMonto(v.cantidadVendida)} uds',
                      valor: v.cantidadVendida,
                      maximo: maxCantidad,
                      valorTexto: formatPrecio(v.totalFacturado),
                      color: color,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sección clientes ──────────────────────────────────────────────────────────

class _SeccionClientes extends StatelessWidget {
  final List<ResumenCliente> clientes;
  const _SeccionClientes({required this.clientes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clientes con más compras',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: clientes.asMap().entries.map((e) {
              final c = e.value;
              final isLast = e.key == clientes.length - 1;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      child: Text(
                        c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    title: Text(c.nombre),
                    subtitle: Text('${c.cantidadVentas} venta(s)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatPrecio(c.totalComprado),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalleClienteScreen(
                          clienteId: c.clienteId,
                          cliente: Cliente(id: c.clienteId, nombre: c.nombre),
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Sección medios de pago ────────────────────────────────────────────────────

class _SeccionMediosPago extends StatelessWidget {
  final List<ResumenMedioPago> mediosPago;
  const _SeccionMediosPago({required this.mediosPago});

  @override
  Widget build(BuildContext context) {
    final totalGeneral = mediosPago.fold(0.0, (s, m) => s + m.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medios de pago', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: PieChart(
                    PieChartData(
                      sections: mediosPago.asMap().entries.map((e) {
                        return PieChartSectionData(
                          value: e.value.total,
                          color: _coloresPie[e.key % _coloresPie.length],
                          radius: 38,
                          title: '',
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: mediosPago.asMap().entries.map((e) {
                      final color = _coloresPie[e.key % _coloresPie.length];
                      final m = e.value;
                      final pct = totalGeneral > 0
                          ? (m.total / totalGeneral * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    m.nombre,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: totalGeneral > 0
                                          ? m.total / totalGeneral
                                          : 0,
                                      minHeight: 4,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Text(
                                '${formatPrecio(m.total)} · ${m.cantidadVentas} venta(s)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sección egresos por categoría ─────────────────────────────────────────────

class _SeccionEgresos extends StatefulWidget {
  final List<ResumenCategoriaGasto> categorias;
  final Map<CategoriaGasto, List<ResumenInsumoGasto>> egresosPorInsumo;

  const _SeccionEgresos({
    required this.categorias,
    required this.egresosPorInsumo,
  });

  @override
  State<_SeccionEgresos> createState() => _SeccionEgresosState();
}

class _SeccionEgresosState extends State<_SeccionEgresos> {
  CategoriaGasto? _categoriaSeleccionada;

  @override
  void didUpdateWidget(_SeccionEgresos old) {
    super.didUpdateWidget(old);
    if (old.categorias != widget.categorias) {
      _categoriaSeleccionada = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Egresos por categoría',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CategoriaGasto?>(
          initialValue: _categoriaSeleccionada,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todas las categorías'),
            ),
            ...widget.categorias.map(
              (c) => DropdownMenuItem(
                value: c.categoria,
                child: Text(categoriaGastoLabel(c.categoria)),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _categoriaSeleccionada = v),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _categoriaSeleccionada == null
                ? _buildDonutCategorias()
                : _buildDonutInsumos(
                    widget.egresosPorInsumo[_categoriaSeleccionada] ?? [],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutCategorias() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Donut(
          secciones: widget.categorias
              .asMap()
              .entries
              .map((e) => (valor: e.value.total, indice: e.key))
              .toList(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.categorias.asMap().entries.map((e) {
              final color = _coloresPie[e.key % _coloresPie.length];
              final cat = e.value;
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        GastosScreen(categoriaInicial: cat.categoria),
                  ),
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FilaLeyenda(
                    color: color,
                    label: categoriaGastoLabel(cat.categoria),
                    total: cat.total,
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutInsumos(List<ResumenInsumoGasto> insumos) {
    if (insumos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Sin detalle de insumos para esta categoría'),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Donut(
          secciones: insumos
              .asMap()
              .entries
              .map((e) => (valor: e.value.total, indice: e.key))
              .toList(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: insumos.asMap().entries.map((e) {
              final color = _coloresPie[e.key % _coloresPie.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FilaLeyenda(
                  color: color,
                  label: e.value.nombre,
                  total: e.value.total,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  final List<({double valor, int indice})> secciones;
  const _Donut({required this.secciones});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 130,
      child: PieChart(
        PieChartData(
          sections: secciones
              .map(
                (s) => PieChartSectionData(
                  value: s.valor,
                  color: _coloresPie[s.indice % _coloresPie.length],
                  radius: 38,
                  title: '',
                ),
              )
              .toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 32,
        ),
      ),
    );
  }
}

class _FilaLeyenda extends StatelessWidget {
  final Color color;
  final String label;
  final double total;
  final Widget? trailing;

  const _FilaLeyenda({
    required this.color,
    required this.label,
    required this.total,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          formatPrecio(total),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (trailing != null) ...[const SizedBox(width: 2), trailing!],
      ],
    );
  }
}

// ── Gráfico de línea: ingresos por día ───────────────────────────────────────

class _GraficoLinea extends StatelessWidget {
  final List<PuntoVentaDia> datos;
  const _GraficoLinea({required this.datos});

  @override
  Widget build(BuildContext context) {
    final maxY = datos.map((d) => d.totalFacturado).reduce(math.max) * 1.25;
    if (maxY == 0) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Sin ventas en el período')),
      );
    }

    final spots = List.generate(
      datos.length,
      (i) => FlSpot(i.toDouble(), datos[i].totalFacturado),
    );

    final color = Theme.of(context).colorScheme.primary;
    final interval = math.max(1.0, (datos.length / 5).ceilToDouble());

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= datos.length || value != i.toDouble()) {
                    return const SizedBox.shrink();
                  }
                  final f = datos[i].fecha;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${f.day}/${f.month}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String valor;
  final VoidCallback? onTap;

  const _MetricCard({required this.label, required this.valor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      valor,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraRanking extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final double valor;
  final double maximo;
  final String valorTexto;
  final Color color;

  const _BarraRanking({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.maximo,
    required this.valorTexto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(valorTexto, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maximo > 0 ? valor / maximo : 0,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
