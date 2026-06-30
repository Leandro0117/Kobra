import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../models/categoria_gasto.dart';
import '../providers/gastos_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class DetalleGastoScreen extends StatefulWidget {
  final int gastoId;

  const DetalleGastoScreen({super.key, required this.gastoId});

  @override
  State<DetalleGastoScreen> createState() => _DetalleGastoScreenState();
}

class _DetalleGastoScreenState extends State<DetalleGastoScreen> {
  Gasto? _gasto;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final gasto = await context.read<GastosProvider>().obtener(widget.gastoId);
    if (!mounted) return;
    setState(() {
      _gasto = gasto;
      _cargando = false;
      _error = gasto == null ? (context.read<GastosProvider>().error ?? 'Error') : null;
    });
  }

  Future<void> _eliminarGasto() async {
    final gasto = _gasto;
    if (gasto == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          '¿Eliminar este gasto por ${formatPrecio(gasto.total)}? '
          'Esta acción no se puede deshacer.',
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

    if (confirmar != true || !mounted) return;

    final gastosProvider = context.read<GastosProvider>();
    final ok = await gastosProvider.eliminar(widget.gastoId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gastosProvider.error ?? 'No se pudo eliminar el gasto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gasto #${widget.gastoId}'),
        actions: [
          if (_gasto != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar gasto',
              onPressed: _eliminarGasto,
            ),
        ],
      ),
      body: _cargando
          ? const EstadoCargando()
          : _error != null
              ? EstadoError(mensaje: _error!, onReintentar: _cargar)
              : _construirDetalle(_gasto!),
    );
  }

  Widget _construirDetalle(Gasto gasto) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Proveedor', style: Theme.of(context).textTheme.labelMedium),
        Text(
          gasto.proveedor?.nombre ?? 'Proveedor #${gasto.proveedorId}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('Categoría', style: Theme.of(context).textTheme.labelMedium),
        Text(categoriaGastoLabel(gasto.categoria), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text('Registrado por', style: Theme.of(context).textTheme.labelMedium),
        Text(gasto.usuario?.nombre ?? '-', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text('Fecha', style: Theme.of(context).textTheme.labelMedium),
        Text(
          '${gasto.fecha.day}/${gasto.fecha.month}/${gasto.fecha.year} ${gasto.fecha.hour.toString().padLeft(2, '0')}:${gasto.fecha.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        const Divider(),
        Text('Insumos comprados', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        ...gasto.detalles.map(
          (d) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(d.insumo?.nombre ?? 'Insumo #${d.insumoId}'),
            subtitle: Text(
              '${formatPrecio(d.precioUnitario)} x ${formatMonto(d.cantidad)}',
            ),
            trailing: Text(formatPrecio(d.subtotal)),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              Text(
                formatPrecio(gasto.total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
