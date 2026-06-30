import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/estadisticas.dart';
import '../models/finanzas.dart';
import '../models/categoria_gasto.dart';
import '../providers/estadisticas_provider.dart';
import '../providers/finanzas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

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
      context.read<FinanzasProvider>().cargar();
      context.read<EstadisticasProvider>().cargar();
    });
  }

  void _cambiarPeriodo(PeriodoEstadisticas periodo) {
    context.read<FinanzasProvider>().cargar(periodo: periodo);
    context.read<EstadisticasProvider>().cargar(periodo: periodo);
  }

  @override
  Widget build(BuildContext context) {
    final finanzasProvider = context.watch<FinanzasProvider>();
    final estadisticasProvider = context.watch<EstadisticasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<PeriodoEstadisticas>(
              initialValue: finanzasProvider.periodo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PeriodoEstadisticas.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(periodoLabel(p))))
                  .toList(),
              onChanged: (p) {
                if (p != null) _cambiarPeriodo(p);
              },
            ),
          ),
          Expanded(child: _buildContenido(context, finanzasProvider, estadisticasProvider)),
        ],
      ),
    );
  }

  Widget _buildContenido(
    BuildContext context,
    FinanzasProvider finanzasProvider,
    EstadisticasProvider estadisticasProvider,
  ) {
    if (finanzasProvider.cargando || estadisticasProvider.cargando) {
      return EstadoCargando(
        avisoServidorLento:
            finanzasProvider.avisoServidorLento || estadisticasProvider.avisoServidorLento,
      );
    }
    if (finanzasProvider.error != null) {
      return EstadoError(
        mensaje: finanzasProvider.error!,
        onReintentar: () => _cambiarPeriodo(finanzasProvider.periodo),
      );
    }
    if (estadisticasProvider.error != null) {
      return EstadoError(
        mensaje: estadisticasProvider.error!,
        onReintentar: () => _cambiarPeriodo(finanzasProvider.periodo),
      );
    }

    final finanzas = finanzasProvider.resumen;
    final estadisticas = estadisticasProvider.resumen;
    if (finanzas == null || estadisticas == null) return const SizedBox.shrink();

    final esGanancia = finanzas.balance >= 0;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          finanzasProvider.cargar(),
          estadisticasProvider.cargar(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Finanzas ──────────────────────────────────
          Text('Finanzas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Ingresos',
                  valor: formatPrecio(finanzas.totalCobrado),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Egresos',
                  valor: formatPrecio(finanzas.totalEgresos),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Por cobrar',
                  valor: formatPrecio(finanzas.porCobrar),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _TarjetaTotal(
                  titulo: esGanancia ? 'Balance (ganancia)' : 'Balance (pérdida)',
                  valor: formatPrecio(finanzas.balance),
                  color: esGanancia ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Egresos por categoría', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (finanzas.egresosPorCategoria.isEmpty)
            const Text('Todavía no hay gastos registrados en este período.')
          else
            ...finanzas.egresosPorCategoria.map((c) => _FilaCategoria(categoria: c)),

          // ── Estadísticas ──────────────────────────────
          const SizedBox(height: 24),
          Text('Ventas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Número de ventas',
                  valor: estadisticas.totalVentas.toString(),
                ),
              ),
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Total facturado',
                  valor: formatPrecio(estadisticas.totalFacturado),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Clientes con más compras', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (estadisticas.topClientes.isEmpty)
            const Text('Todavía no hay datos suficientes.')
          else
            ...estadisticas.topClientes.map((c) => _FilaCliente(cliente: c)),
          const SizedBox(height: 16),
          Text('Productos más vendidos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (estadisticas.topProductos.isEmpty)
            const Text('Todavía no hay datos suficientes.')
          else
            ...estadisticas.topProductos.map((p) => _FilaProducto(producto: p)),
        ],
      ),
    );
  }
}

class _TarjetaTotal extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color? color;

  const _TarjetaTotal({required this.titulo, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaCategoria extends StatelessWidget {
  final ResumenCategoriaGasto categoria;

  const _FilaCategoria({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.label_outline),
      title: Text(categoriaGastoLabel(categoria.categoria)),
      trailing: Text(
        formatPrecio(categoria.total),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  final ResumenCliente cliente;

  const _FilaCliente({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(cliente.nombre),
      subtitle: Text(
        '${cliente.cantidadVentas} venta(s) · ${formatMonto(cliente.cantidadProductos)} producto(s)',
      ),
      trailing: Text(
        formatPrecio(cliente.totalComprado),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  final ResumenProducto producto;

  const _FilaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(producto.nombre),
      subtitle: Text('${formatMonto(producto.cantidadVendida)} unidad(es) vendidas'),
      trailing: Text(
        formatPrecio(producto.totalFacturado),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
