import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/venta.dart';
import '../providers/ventas_provider.dart';
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
      appBar: AppBar(title: Text('Venta #${widget.ventaId}')),
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
          '${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year} ${venta.fecha.hour.toString().padLeft(2, '0')}:${venta.fecha.minute.toString().padLeft(2, '0')}',
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
              '\$${d.precioUnitario.toStringAsFixed(2)} x ${d.cantidad.toStringAsFixed(0)}',
            ),
            trailing: Text('\$${d.subtotal.toStringAsFixed(2)}'),
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
                '\$${venta.total.toStringAsFixed(2)}',
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
