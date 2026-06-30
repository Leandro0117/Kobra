import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/estadisticas.dart';
import '../models/finanzas.dart';
import '../models/categoria_gasto.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final finanzasProvider = context.watch<FinanzasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Finanzas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<PeriodoEstadisticas>(
              initialValue: finanzasProvider.periodo,
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: PeriodoEstadisticas.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(periodoLabel(p))))
                  .toList(),
              onChanged: (p) {
                if (p != null) finanzasProvider.cargar(periodo: p);
              },
            ),
          ),
          Expanded(child: _buildContenido(context, finanzasProvider)),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context, FinanzasProvider finanzasProvider) {
    if (finanzasProvider.cargando) {
      return EstadoCargando(avisoServidorLento: finanzasProvider.avisoServidorLento);
    }
    if (finanzasProvider.error != null) {
      return EstadoError(
        mensaje: finanzasProvider.error!,
        onReintentar: () => finanzasProvider.cargar(),
      );
    }
    final resumen = finanzasProvider.resumen;
    if (resumen == null) return const SizedBox.shrink();

    final esGanancia = resumen.balance >= 0;

    return RefreshIndicator(
      onRefresh: () => finanzasProvider.cargar(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Ingresos (ventas)',
                  valor: formatPrecio(resumen.totalIngresos),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TarjetaTotal(
                  titulo: 'Egresos (gastos)',
                  valor: formatPrecio(resumen.totalEgresos),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TarjetaTotal(
            titulo: esGanancia ? 'Balance (ganancia)' : 'Balance (pérdida)',
            valor: formatPrecio(resumen.balance),
            color: esGanancia ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text('Egresos por categoría', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (resumen.egresosPorCategoria.isEmpty)
            const Text('Todavía no hay gastos registrados en este período.')
          else
            ...resumen.egresosPorCategoria.map((c) => _FilaCategoria(categoria: c)),
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
