import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/producto.dart';
import '../models/variante.dart';
import '../models/detalle_venta.dart';
import '../models/venta.dart';
import '../providers/clientes_provider.dart';
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
  final List<_LineaCarrito> _carrito = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargar();
      context.read<ProductosProvider>().cargar();
    });
  }

  double get _total => _carrito.fold(0, (sum, l) => sum + l.subtotal);

  void _agregarVariante(Variante variante) {
    final existente = _carrito.where((l) => l.variante.id == variante.id).firstOrNull;
    setState(() {
      if (existente != null) {
        existente.cantidad += 1;
      } else {
        _carrito.add(_LineaCarrito(
          variante: variante,
          nombreProducto: _productoSeleccionado!.nombre,
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

  Future<void> _guardarVenta() async {
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
    final venta = await ventasProvider.crear(
      clienteId: _clienteSeleccionado!.id,
      detalles: detalles,
      estado: _estadoSeleccionado,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (venta != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Venta registrada correctamente')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ventasProvider.error ?? 'No se pudo registrar la venta')),
      );
    }
  }

  Future<bool> _confirmarDescarte() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Tienes productos en el carrito. Si salís ahora se perderán.'),
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
    final productosConVariantes =
        productosProvider.productos.where((p) => p.variantes.isNotEmpty).toList();

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
      appBar: AppBar(title: const Text('Nueva venta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Selector de cliente con búsqueda ──
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

            // ── Estado inicial ──
            DropdownButtonFormField<EstadoVenta>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: EstadoVenta.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(estadoLabel(e))))
                  .toList(),
              onChanged: (e) => setState(() => _estadoSeleccionado = e!),
            ),
            const SizedBox(height: 12),

            // ── Selector de producto ──
            if (productosProvider.cargando)
              EstadoCargando(avisoServidorLento: productosProvider.avisoServidorLento)
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
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.nombre)))
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
                          label: Text('${v.nombre}  ${formatPrecio(v.precio)}'),
                          onPressed: () => _agregarVariante(v),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Carrito (ocupa el espacio restante) ──
            Expanded(
              child: _carrito.isEmpty
                  ? const Center(child: Text('Agrega productos tocando los chips de arriba'))
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total estimado', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatPrecio(_total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Text(
              'El total final se recalcula en el servidor al guardar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _guardando ? null : _guardarVenta,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
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
      _filtrados = widget.clientes
          .where((c) => c.nombre.toLowerCase().contains(q))
          .toList();
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
