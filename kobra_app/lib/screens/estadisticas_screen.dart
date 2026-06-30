import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/estadisticas.dart';
import '../providers/estadisticas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EstadisticasProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadisticasProvider = context.watch<EstadisticasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<PeriodoEstadisticas>(
              initialValue: estadisticasProvider.periodo,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PeriodoEstadisticas.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(periodoLabel(p))))
                  .toList(),
              onChanged: (p) {
                if (p != null) estadisticasProvider.cargar(periodo: p);
              },
            ),
          ),
          Expanded(child: _buildContenido(context, estadisticasProvider)),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context, EstadisticasProvider estadisticasProvider) {
    if (estadisticasProvider.cargando) {
      return EstadoCargando(avisoServidorLento: estadisticasProvider.avisoServidorLento);
    }
    if (estadisticasProvider.error != null) {
      return EstadoError(
        mensaje: estadisticasProvider.error!,
        onReintentar: () => estadisticasProvider.cargar(),
      );
    }
    final resumen = estadisticasProvider.resumen;
    if (resumen == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => estadisticasProvider.cargar(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'No incluye ventas canceladas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Ventas totales',
                  valor: resumen.totalVentas.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Total facturado',
                  valor: formatPrecio(resumen.totalFacturado),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Clientes con más ventas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (resumen.topClientes.isEmpty)
            const Text('Todavía no hay datos suficientes.')
          else
            ...resumen.topClientes.map((c) => _FilaCliente(cliente: c)),
          const SizedBox(height: 24),
          Text('Productos más vendidos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (resumen.topProductos.isEmpty)
            const Text('Todavía no hay datos suficientes.')
          else
            ...resumen.topProductos.map((p) => _FilaProducto(producto: p)),
        ],
      ),
    );
  }
}

class _TarjetaTotal extends StatelessWidget {
  final String titulo;
  final String valor;

  const _TarjetaTotal({required this.titulo, required this.valor});

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
            Text(valor, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
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
        '${cliente.cantidadVentas} venta(s) · ${formatMonto(cliente.cantidadProductos)} producto(s) comprados',
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
