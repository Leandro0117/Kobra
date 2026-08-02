import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/medio_pago.dart';
import '../models/producto.dart';
import '../models/variante.dart';
import '../models/detalle_venta.dart';
import '../models/venta.dart';
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

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? _clienteSeleccionado;
  Producto? _productoSeleccionado;
  EstadoVenta _estadoSeleccionado = EstadoVenta.PENDIENTE;
  MedioPago? _medioPagoSeleccionado;
  final List<_LineaCarrito> _carrito = [];
  bool _guardando = false;
  bool _modoRapido = false;

  TipoDescuento _tipoDescuento = TipoDescuento.PORCENTAJE;
  final _descuentoController = TextEditingController();

  DateTime _fechaVenta = DateTime.now();
  DateTime? _fechaEntregaProgramada;
  bool _fechasExpandidas = false;

  @override
  void initState() {
    super.initState();
    _descuentoController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargar();
      context.read<ProductosProvider>().cargar();
      context.read<MediosPagoProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _descuentoController.dispose();
    super.dispose();
  }

  bool get _fechasModificadas {
    final hoy = DateTime.now();
    final mismoDia = _fechaVenta.year == hoy.year &&
        _fechaVenta.month == hoy.month &&
        _fechaVenta.day == hoy.day;
    return !mismoDia || _fechaEntregaProgramada != null;
  }

  Future<void> _seleccionarFechaVenta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaVenta),
    );
    if (!mounted) return;
    setState(() {
      _fechaVenta = DateTime(
        fecha.year, fecha.month, fecha.day,
        hora?.hour ?? _fechaVenta.hour,
        hora?.minute ?? _fechaVenta.minute,
      );
    });
  }

  Future<void> _seleccionarFechaEntregaProgramada() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntregaProgramada ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    setState(() => _fechaEntregaProgramada = fecha);
  }

  Widget _buildFechasSection() {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');
    final colorScheme = Theme.of(context).colorScheme;
    final modificadas = _fechasModificadas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _fechasExpandidas = !_fechasExpandidas),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: modificadas ? Colors.amber.shade700 : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fechas opcionales',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: modificadas ? Colors.amber.shade700 : null,
                    fontWeight: modificadas ? FontWeight.w600 : null,
                  ),
                ),
                if (modificadas) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Modificadas',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _fechasExpandidas ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_fechasExpandidas) ...[
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Fecha de la venta'),
            subtitle: Text(fmt.format(_fechaVenta)),
            trailing: TextButton(
              onPressed: _seleccionarFechaVenta,
              child: const Text('Cambiar'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Entrega programada'),
            subtitle: Text(
              _fechaEntregaProgramada != null
                  ? fmtFecha.format(_fechaEntregaProgramada!)
                  : 'Sin fecha',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _seleccionarFechaEntregaProgramada,
                  child: const Text('Elegir'),
                ),
                if (_fechaEntregaProgramada != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _fechaEntregaProgramada = null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  double get _subtotal => _carrito.fold(0, (sum, l) => sum + l.subtotal);

  double get _descuentoAplicado {
    final valor = double.tryParse(_descuentoController.text) ?? 0;
    if (_tipoDescuento == TipoDescuento.PORCENTAJE) {
      return _subtotal * (valor / 100);
    }
    return valor;
  }

  double get _total =>
      (_subtotal - _descuentoAplicado).clamp(0, double.infinity);

  void _agregarVariante(Variante variante) {
    final existente = _carrito
        .where((l) => l.variante.id == variante.id)
        .firstOrNull;
    setState(() {
      if (existente != null) {
        existente.cantidad += 1;
      } else {
        _carrito.add(
          _LineaCarrito(
            variante: variante,
            nombreProducto: _productoSeleccionado!.nombre,
            cantidad: 1,
          ),
        );
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _tipoDescuento == TipoDescuento.PORCENTAJE
                      ? 'Desc. (%)'
                      : 'Desc. (\$)',
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

  Future<void> _guardarVenta() async {
    if (!_modoRapido && _clienteSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un cliente')));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }
    if (_estadoSeleccionado == EstadoVenta.PAGADO && _medioPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un medio de pago')),
      );
      return;
    }

    setState(() => _guardando = true);

    final detalles = _carrito
        .map(
          (l) => DetalleVenta(
            varianteId: l.variante.id,
            cantidad: l.cantidad.toDouble(),
            precioUnitario: l.variante.precio,
          ),
        )
        .toList();

    final ventasProvider = context.read<VentasProvider>();
    final hoy = DateTime.now();
    final fechaEsHoy = _fechaVenta.year == hoy.year &&
        _fechaVenta.month == hoy.month &&
        _fechaVenta.day == hoy.day;

    final venta = await ventasProvider.crear(
      clienteId: _modoRapido ? null : _clienteSeleccionado?.id,
      detalles: detalles,
      estado: _estadoSeleccionado,
      descuento: double.tryParse(_descuentoController.text) ?? 0,
      tipoDescuento: _tipoDescuento,
      medioPagoId: _medioPagoSeleccionado?.id,
      fechaVenta: fechaEsHoy ? null : _fechaVenta,
      fechaEntregaProgramada: _fechaEntregaProgramada,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (venta != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ventasProvider.error ?? 'No se pudo registrar la venta',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmarDescarte() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
          'Tienes productos en el carrito. Si salís ahora se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();
    final productosProvider = context.watch<ProductosProvider>();
    final productosConVariantes = productosProvider.productos
        .where((p) => p.variantes.isNotEmpty)
        .toList();

    final mediosPagoProvider = context.watch<MediosPagoProvider>();

    return PopScope(
      canPop: _carrito.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmarDescarte() && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_modoRapido ? 'Nueva venta rápida' : 'Nueva venta'),
          actions: [
            IconButton(
              tooltip: _modoRapido ? 'Modo normal' : 'Venta rápida (sin cliente)',
              icon: Icon(
                Icons.bolt,
                color: _modoRapido ? Colors.purple : null,
              ),
              onPressed: () => setState(() {
                _modoRapido = !_modoRapido;
                _clienteSeleccionado = null;
              }),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Selector de producto ──
              if (productosProvider.cargando)
                EstadoCargando(
                  avisoServidorLento: productosProvider.avisoServidorLento,
                )
              else if (productosProvider.error != null)
                EstadoError(
                  mensaje: productosProvider.error!,
                  onReintentar: () => productosProvider.cargar(),
                )
              else if (productosConVariantes.isEmpty)
                const Text('Todavía no hay variantes de producto registradas.')
              else ...[
                DropdownButtonFormField<Producto>(
                  initialValue: _productoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                  ),
                  items: productosConVariantes
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p, child: Text(p.nombre)),
                      )
                      .toList(),
                  onChanged: (p) => setState(() => _productoSeleccionado = p),
                ),
                if (_productoSeleccionado != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _productoSeleccionado!.variantes
                        .map(
                          (v) => ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: Text(
                              '${v.nombre}  ${formatPrecio(v.precio)}',
                            ),
                            onPressed: () => _agregarVariante(v),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              // ── Estado de venta ──
              DropdownButtonFormField<EstadoVenta>(
                initialValue: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: EstadoVenta.values
                    .where((e) => e != EstadoVenta.PAGO_PARCIAL)
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(estadoLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (e) => setState(() {
                  _estadoSeleccionado = e!;
                  if (e != EstadoVenta.PAGADO) _medioPagoSeleccionado = null;
                }),
              ),
              if (_estadoSeleccionado == EstadoVenta.PAGADO) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<MedioPago?>(
                  initialValue: _medioPagoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Medio de pago',
                    border: OutlineInputBorder(),
                  ),
                  items: mediosPagoProvider.mediosActivos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.nombre)))
                    .toList(),
                  onChanged: (m) => setState(() => _medioPagoSeleccionado = m),
                ),
              ],
              const SizedBox(height: 12),

              // ── Selector de cliente (oculto en modo rápido) ──
              if (!_modoRapido) ...[
                if (clientesProvider.cargando)
                  EstadoCargando(
                    avisoServidorLento: clientesProvider.avisoServidorLento,
                  )
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
              ],
              _buildFechasSection(),
              const Divider(height: 1),

              // ── Carrito (ocupa el espacio restante) ──
              Expanded(
                child: _carrito.isEmpty
                    ? const Center(
                        child: Text(
                          'Agrega productos tocando los chips de arriba',
                        ),
                      )
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
                                  onPressed: () => _cambiarCantidad(
                                    linea,
                                    linea.cantidad - 1,
                                  ),
                                ),
                                Text('${linea.cantidad}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _cambiarCantidad(
                                    linea,
                                    linea.cantidad + 1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      setState(() => _carrito.remove(linea)),
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                      Text(
                        'Descuento',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '− ${formatPrecio(_descuentoAplicado)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatPrecio(_total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'El total final se recalcula en el servidor al guardar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _guardando ? null : _guardarVenta,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar venta'),
              ),
            ],
          ),
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
      _filtrados = q.isEmpty
          ? widget.clientes
          : widget.clientes
                .where((c) => c.nombre.toLowerCase().contains(q))
                .toList();
    });
  }

  Future<void> _crearCliente(String nombreSugerido) async {
    final nombreController = TextEditingController(text: nombreSugerido);
    final telefonoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                autofocus: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final clientesProvider = context.read<ClientesProvider>();
    final nombre = nombreController.text.trim();
    final telefono = telefonoController.text.trim();
    final ok = await clientesProvider.crear(
      nombre,
      telefono.isNotEmpty ? telefono : null,
    );

    if (!mounted) return;
    if (ok) {
      final nuevo = clientesProvider.clientes
          .where((c) => c.nombre == nombre)
          .lastOrNull;
      if (nuevo != null) Navigator.of(context).pop(nuevo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            clientesProvider.error ?? 'No se pudo crear el cliente',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final sinResultados = _filtrados.isEmpty && query.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                child: sinResultados
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_add_outlined),
                            ),
                            title: Text('Crear "$query"'),
                            subtitle: const Text('Nuevo cliente'),
                            onTap: () => _crearCliente(query),
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = _filtrados[index];
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(c.nombre),
                            subtitle: c.telefono != null
                                ? Text(c.telefono!)
                                : null,
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
