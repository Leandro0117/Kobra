import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/detalle_venta.dart';
import '../models/variante.dart';
import '../models/venta.dart';
import '../models/medio_pago.dart';
import '../providers/clientes_provider.dart';
import '../providers/medios_pago_provider.dart';
import '../providers/productos_provider.dart';
import '../providers/ventas_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class _LineaCarrito {
  final Variante variante;
  final String nombreProducto;
  int cantidad;

  _LineaCarrito({
    required this.variante,
    required this.nombreProducto,
    required this.cantidad,
  });

  double get subtotal => variante.precio * cantidad;
  String get titulo => '$nombreProducto — ${variante.nombre}';
}

class EditarVentaScreen extends StatefulWidget {
  final Venta venta;

  const EditarVentaScreen({super.key, required this.venta});

  @override
  State<EditarVentaScreen> createState() => _EditarVentaScreenState();
}

class _EditarVentaScreenState extends State<EditarVentaScreen> {
  late Cliente? _clienteSeleccionado;
  late List<_LineaCarrito> _carrito;
  bool _guardando = false;
  int? _productoSeleccionadoId;

  late TipoDescuento _tipoDescuento;
  late final TextEditingController _descuentoController;
  MedioPago? _medioPagoSeleccionado;

  @override
  void initState() {
    super.initState();
    _clienteSeleccionado = widget.venta.cliente;
    _tipoDescuento = widget.venta.tipoDescuento;
    final descVal = widget.venta.descuento;
    _descuentoController = TextEditingController(
      text: descVal > 0 ? descVal.toStringAsFixed(descVal.truncateToDouble() == descVal ? 0 : 2) : '',
    );
    _descuentoController.addListener(() => setState(() {}));
    _carrito = widget.venta.detalles
        .where((d) => d.variante != null)
        .map(
          (d) => _LineaCarrito(
            variante: d.variante!,
            nombreProducto: d.variante!.producto?.nombre ?? '',
            cantidad: d.cantidad.round(),
          ),
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargar();
      context.read<ProductosProvider>().cargar();
      final mediosProvider = context.read<MediosPagoProvider>();
      if (mediosProvider.medios.isEmpty) mediosProvider.cargar();
      // Pre-seleccionar el medio de pago actual de la venta
      if (widget.venta.medioPago != null) {
        final medio = mediosProvider.mediosActivos
            .where((m) => m.id == widget.venta.medioPago!.id)
            .firstOrNull;
        if (medio != null && mounted) setState(() => _medioPagoSeleccionado = medio);
      }
    });
  }

  @override
  void dispose() {
    _descuentoController.dispose();
    super.dispose();
  }

  double get _subtotal => _carrito.fold(0, (sum, l) => sum + l.subtotal);

  double get _descuentoAplicado {
    final valor = double.tryParse(_descuentoController.text) ?? 0;
    if (_tipoDescuento == TipoDescuento.PORCENTAJE) {
      return _subtotal * (valor / 100);
    }
    return valor;
  }

  double get _total => (_subtotal - _descuentoAplicado).clamp(0, double.infinity);

  void _agregarVariante(Variante variante, String nombreProducto) {
    final existente = _carrito.where((l) => l.variante.id == variante.id).firstOrNull;
    setState(() {
      if (existente != null) {
        existente.cantidad += 1;
      } else {
        _carrito.add(_LineaCarrito(
          variante: variante,
          nombreProducto: nombreProducto,
          cantidad: 1,
        ));
      }
    });
  }

  void _cambiarCantidad(_LineaCarrito linea, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.remove(linea);
      } else {
        linea.cantidad = nuevaCantidad;
      }
    });
  }

  Future<void> _seleccionarCliente(List<Cliente> clientes) async {
    final seleccionado = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BuscadorClientes(clientes: clientes),
    );
    if (seleccionado != null) {
      setState(() => _clienteSeleccionado = seleccionado);
    }
  }

  Widget _buildDescuentoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleDescuento(
                tipo: _tipoDescuento,
                onChanged: (t) => setState(() {
                  _tipoDescuento = t;
                  _descuentoController.clear();
                }),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _descuentoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _tipoDescuento == TipoDescuento.PORCENTAJE ? 'Desc. (%)' : 'Desc. (\$)',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMedioPagoWidget(List<MedioPago> mediosActivos) {
    if (mediosActivos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Medio de pago', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: mediosActivos.map((medio) {
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
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un cliente')));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agrega al menos un producto')));
      return;
    }

    setState(() => _guardando = true);

    final detalles = _carrito
        .map((l) => DetalleVenta(
              varianteId: l.variante.id,
              cantidad: l.cantidad.toDouble(),
              precioUnitario: l.variante.precio,
            ))
        .toList();

    final ventasProvider = context.read<VentasProvider>();
    final actualizada = await ventasProvider.actualizar(
      widget.venta.id,
      detalles: detalles,
      clienteId: _clienteSeleccionado!.id,
      descuento: double.tryParse(_descuentoController.text) ?? 0,
      tipoDescuento: _tipoDescuento,
      medioPagoId: _medioPagoSeleccionado?.id,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (actualizada != null) {
      Navigator.of(context).pop(actualizada);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ventasProvider.error ?? 'No se pudo actualizar la venta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();
    final productosProvider = context.watch<ProductosProvider>();
    final mediosActivos = context.watch<MediosPagoProvider>().mediosActivos;
    final productosConVariantes =
        productosProvider.productos.where((p) => p.variantes.isNotEmpty).toList();
    final productoSeleccionado = _productoSeleccionadoId != null
        ? productosConVariantes.where((p) => p.id == _productoSeleccionadoId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(title: Text('Editar venta #${widget.venta.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Selector de cliente ──
            if (clientesProvider.cargando)
              EstadoCargando(avisoServidorLento: clientesProvider.avisoServidorLento)
            else if (clientesProvider.error != null)
              EstadoError(
                mensaje: clientesProvider.error!,
                onReintentar: () => clientesProvider.cargar(),
              )
            else
              GestureDetector(
                onTap: () => _seleccionarCliente(clientesProvider.clientes),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: Text(
                    _clienteSeleccionado?.nombre ?? 'Buscar cliente…',
                    style: TextStyle(
                      color: _clienteSeleccionado != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // ── Selector de producto para agregar ──
            if (productosProvider.cargando)
              EstadoCargando(avisoServidorLento: productosProvider.avisoServidorLento)
            else if (productosProvider.error != null)
              EstadoError(
                mensaje: productosProvider.error!,
                onReintentar: () => productosProvider.cargar(),
              )
            else if (productosConVariantes.isEmpty)
              const Text('No hay productos con variantes registrados.')
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _productoSeleccionadoId,
                decoration: const InputDecoration(
                  labelText: 'Agregar producto',
                  border: OutlineInputBorder(),
                ),
                items: productosConVariantes
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                    .toList(),
                onChanged: (id) => setState(() => _productoSeleccionadoId = id),
              ),
              if (productoSeleccionado != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: productoSeleccionado.variantes
                      .map(
                        (v) => ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text('${v.nombre}  ${formatPrecio(v.precio)}'),
                          onPressed: () =>
                              _agregarVariante(v, productoSeleccionado.nombre),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Carrito ──
            Expanded(
              child: _carrito.isEmpty
                  ? const Center(child: Text('No hay productos en la venta'))
                  : ListView.builder(
                      itemCount: _carrito.length,
                      itemBuilder: (context, index) {
                        final linea = _carrito[index];
                        return ListTile(
                          dense: true,
                          title: Text(linea.titulo),
                          subtitle: Text(
                            '${formatPrecio(linea.variante.precio)} x ${linea.cantidad} = ${formatPrecio(linea.subtotal)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () =>
                                    _cambiarCantidad(linea, linea.cantidad - 1),
                              ),
                              Text('${linea.cantidad}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    _cambiarCantidad(linea, linea.cantidad + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(() => _carrito.remove(linea)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildDescuentoWidget(),
            _buildMedioPagoWidget(mediosActivos),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
                  Text(formatPrecio(_subtotal)),
                ],
              ),
            ),
            if (_descuentoAplicado > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Descuento', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '− ${formatPrecio(_descuentoAplicado)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                Text(formatPrecio(_total), style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'El total final se recalcula en el servidor al guardar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleDescuento extends StatelessWidget {
  final TipoDescuento tipo;
  final ValueChanged<TipoDescuento> onChanged;

  const _ToggleDescuento({required this.tipo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TipoDescuento>(
      segments: const [
        ButtonSegment(value: TipoDescuento.PORCENTAJE, label: Text('%')),
        ButtonSegment(value: TipoDescuento.MONTO_FIJO, label: Text('\$')),
      ],
      selected: {tipo},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _BuscadorClientes extends StatefulWidget {
  final List<Cliente> clientes;

  const _BuscadorClientes({required this.clientes});

  @override
  State<_BuscadorClientes> createState() => _BuscadorClientesState();
}

class _BuscadorClientesState extends State<_BuscadorClientes> {
  final _controller = TextEditingController();
  List<Cliente> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.clientes;
    _controller.addListener(_filtrar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _controller.text.toLowerCase();
    setState(() {
      _filtrados =
          widget.clientes.where((c) => c.nombre.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtrados.isEmpty
                    ? const Center(child: Text('Sin resultados'))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = _filtrados[index];
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(c.nombre),
                            subtitle: c.telefono != null ? Text(c.telefono!) : null,
                            onTap: () => Navigator.of(context).pop(c),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
