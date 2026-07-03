import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medio_pago.dart';
import '../models/venta.dart';
import '../providers/medios_pago_provider.dart';
import '../providers/ventas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';
import 'editar_venta_screen.dart';

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
  bool _registrandoPago = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _irAEditar() async {
    final venta = _venta;
    if (venta == null) return;
    final actualizada = await Navigator.of(context).push<Venta>(
      MaterialPageRoute(builder: (_) => EditarVentaScreen(venta: venta)),
    );
    if (actualizada != null && mounted) {
      setState(() => _venta = actualizada);
    }
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

  Future<void> _mostrarModalPago(Venta venta) async {
    // Asegurar que los medios estén cargados antes de abrir el modal
    final mediosProvider = context.read<MediosPagoProvider>();
    if (mediosProvider.medios.isEmpty) {
      await mediosProvider.cargar();
    }
    if (!mounted) return;

    final controller = TextEditingController();
    final result = await showModalBottomSheet<({double monto, int? medioPagoId})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModalPago(
        venta: venta,
        controller: controller,
        mediosActivos: mediosProvider.mediosActivos,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _registrandoPago = true);
    final actualizada = await context.read<VentasProvider>().registrarPago(
          venta.id,
          result.monto,
          medioPagoId: result.medioPagoId,
        );
    if (!mounted) return;
    setState(() {
      _registrandoPago = false;
      if (actualizada != null) _venta = actualizada;
    });
    if (actualizada == null) {
      final error = context.read<VentasProvider>().error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'No se pudo registrar el pago')));
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
          if (_venta != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar venta',
              onPressed: _irAEditar,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar venta',
              onPressed: _eliminarVenta,
            ),
          ],
        ],
      ),
      body: _cargando
          ? const EstadoCargando()
          : _error != null
              ? EstadoError(mensaje: _error!, onReintentar: _cargar)
              : _construirDetalle(_venta!),
    );
  }

  Widget _buildAccionesEstado(Venta venta) {
    final cargando = _actualizandoEstado || _registrandoPago;

    Widget estadoBadge() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estado', style: Theme.of(context).textTheme.labelMedium),
          _EstadoBadge(estado: venta.estado),
        ],
      );
    }

    if (cargando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          estadoBadge(),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    switch (venta.estado) {
      case EstadoVenta.PENDIENTE:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            estadoBadge(),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _cambiarEstado(EstadoVenta.POR_PAGAR),
              child: const Text('Confirmar — pasar a Por pagar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _confirmarCancelar(venta),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: const Text('Cancelar venta'),
            ),
          ],
        );

      case EstadoVenta.POR_PAGAR:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            estadoBadge(),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _mostrarModalPago(venta),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Registrar pago'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _confirmarCancelar(venta),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: const Text('Cancelar venta'),
            ),
          ],
        );

      case EstadoVenta.PAGADO:
      case EstadoVenta.CANCELADO:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            estadoBadge(),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: null,
              child: Text(
                venta.estado == EstadoVenta.PAGADO ? 'Venta cerrada' : 'Venta cancelada',
              ),
            ),
          ],
        );
    }
  }

  Future<void> _confirmarCancelar(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await _cambiarEstado(EstadoVenta.CANCELADO);
    }
  }

  Widget _buildResumenFinanciero(Venta venta) {
    final subtotal = venta.detalles.fold<double>(0, (s, d) => s + d.subtotal);
    final tieneDescuento = venta.descuento > 0;
    final colorPrimario = Theme.of(context).colorScheme.primary;
    // Si la venta está pagada se considera saldo 0 independientemente de montoPagado
    final saldoPendiente = venta.estado == EstadoVenta.PAGADO ? 0.0 : venta.saldoPendiente;
    final porcentajePagado = venta.estado == EstadoVenta.PAGADO ? 1.0 : venta.porcentajePagado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tieneDescuento) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
                Text(formatPrecio(subtotal)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  venta.tipoDescuento == TipoDescuento.PORCENTAJE
                      ? 'Descuento (${venta.descuento.toStringAsFixed(venta.descuento.truncateToDouble() == venta.descuento ? 0 : 1)}%)'
                      : 'Descuento',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text('− ${formatPrecio(subtotal - venta.total)}',
                    style: TextStyle(color: colorPrimario)),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              Text(formatPrecio(venta.total), style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pagos', style: Theme.of(context).textTheme.labelMedium),
            Text(
              '${formatPrecio(venta.montoPagado)} / ${formatPrecio(venta.total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentajePagado,
            minHeight: 7,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              saldoPendiente == 0 ? Colors.green : colorPrimario,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              saldoPendiente > 0
                  ? 'Saldo pendiente: ${formatPrecio(saldoPendiente)}'
                  : 'Pagado completamente',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: saldoPendiente > 0
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
            ),
          ],
        ),
        if (venta.medioPago != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medio de pago', style: Theme.of(context).textTheme.bodySmall),
              Text(
                venta.medioPago!.nombre,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ],
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
        _buildResumenFinanciero(venta),
        const SizedBox(height: 24),
        _buildAccionesEstado(venta),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Modal de pago ─────────────────────────────────────────────────────────────

class _ModalPago extends StatefulWidget {
  final Venta venta;
  final TextEditingController controller;
  final List<MedioPago> mediosActivos;

  const _ModalPago({
    required this.venta,
    required this.controller,
    required this.mediosActivos,
  });

  @override
  State<_ModalPago> createState() => _ModalPagoState();
}

class _ModalPagoState extends State<_ModalPago> {
  MedioPago? _medioPagoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar pago', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Saldo pendiente: ${formatPrecio(widget.venta.saldoPendiente)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto a registrar',
              prefixText: '\$ ',
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: () => widget.controller.text =
                    widget.venta.saldoPendiente.toStringAsFixed(0),
                child: const Text('Pago total'),
              ),
            ),
          ),
          if (widget.mediosActivos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Medio de pago', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.mediosActivos.map((medio) {
                final seleccionado = _medioPagoSeleccionado?.id == medio.id;
                return ChoiceChip(
                  label: Text(medio.nombre),
                  selected: seleccionado,
                  onSelected: (_) => setState(() {
                    _medioPagoSeleccionado = seleccionado ? null : medio;
                  }),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(widget.controller.text);
              if (v != null && v > 0) {
                Navigator.of(context).pop((
                  monto: v,
                  medioPagoId: _medioPagoSeleccionado?.id,
                ));
              }
            },
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
  }
}

// ── Badge de estado ───────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final EstadoVenta estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (estado) {
      EstadoVenta.PENDIENTE  => (const Color(0xFF854F0B), const Color(0xFFFAEEDA)),
      EstadoVenta.POR_PAGAR  => (const Color(0xFF185FA5), const Color(0xFFE6F1FB)),
      EstadoVenta.PAGADO     => (const Color(0xFF3B6D11), const Color(0xFFEAF3DE)),
      EstadoVenta.CANCELADO  => (const Color(0xFF5F5E5A), const Color(0xFFF1EFE8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(estadoLabel(estado), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
