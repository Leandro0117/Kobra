import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/venta.dart';
import '../providers/ventas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class DetalleVentaScreen extends StatefulWidget {
  final int ventaId;

  const DetalleVentaScreen({super.key, required this.ventaId});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  Venta? _venta;
  bool _cargando = true;
  String? _error;
  bool _actualizandoEstado = false;

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
    final venta = await context.read<VentasProvider>().obtener(widget.ventaId);
    if (!mounted) return;
    setState(() {
      _venta = venta;
      _cargando = false;
      _error = venta == null ? (context.read<VentasProvider>().error ?? 'Error') : null;
    });
  }

  Future<void> _eliminarVenta() async {
    final venta = _venta;
    if (venta == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text(
          '¿Eliminar esta venta por ${formatPrecio(venta.total)}? '
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

    final ventasProvider = context.read<VentasProvider>();
    final ok = await ventasProvider.eliminar(widget.ventaId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ventasProvider.error ?? 'No se pudo eliminar la venta')),
      );
    }
  }

  Future<void> _cambiarEstado(EstadoVenta nuevoEstado) async {
    setState(() => _actualizandoEstado = true);
    final actualizada = await context.read<VentasProvider>().cambiarEstado(
          widget.ventaId,
          nuevoEstado,
        );
    if (!mounted) return;
    setState(() {
      _actualizandoEstado = false;
      if (actualizada != null) _venta = actualizada;
    });
    if (actualizada == null) {
      final error = context.read<VentasProvider>().error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'No se pudo cambiar el estado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta #${widget.ventaId}'),
        actions: [
          if (_venta != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar venta',
              onPressed: _eliminarVenta,
            ),
        ],
      ),
      body: _cargando
          ? const EstadoCargando()
          : _error != null
              ? EstadoError(mensaje: _error!, onReintentar: _cargar)
              : _construirDetalle(_venta!),
    );
  }

  Widget _construirDetalle(Venta venta) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cliente', style: Theme.of(context).textTheme.labelMedium),
        Text(
          venta.cliente?.nombre ?? 'Cliente #${venta.clienteId}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('Vendedor', style: Theme.of(context).textTheme.labelMedium),
        Text(venta.vendedor?.nombre ?? '-', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text('Fecha', style: Theme.of(context).textTheme.labelMedium),
        Text(
          formatFechaHora(venta.fecha),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        const Divider(),
        Text('Productos', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        ...venta.detalles.map(
          (d) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(d.variante?.nombreCompleto() ?? 'Variante #${d.varianteId}'),
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
                formatPrecio(venta.total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Estado', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        if (_actualizandoEstado)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            children: EstadoVenta.values.map((e) {
              final seleccionado = e == venta.estado;
              return ChoiceChip(
                label: Text(estadoLabel(e)),
                selected: seleccionado,
                onSelected: (_) => seleccionado ? null : _cambiarEstado(e),
              );
            }).toList(),
          ),
      ],
    );
  }
}
