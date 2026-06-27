import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/variante.dart';
import '../models/detalle_venta.dart';
import '../models/venta.dart';
import '../providers/clientes_provider.dart';
import '../providers/productos_provider.dart';
import '../providers/ventas_provider.dart';
import '../widgets/estado_carga.dart';

class _LineaCarrito {
  final Variante variante;
  double cantidad;

  _LineaCarrito({required this.variante, required this.cantidad});

  double get subtotal => variante.precio * cantidad;
}

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? _clienteSeleccionado;
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

  double get _total => _carrito.fold(0, (sum, linea) => sum + linea.subtotal);

  void _agregarVariante(Variante variante) {
    final coincidencias = _carrito.where((l) => l.variante.id == variante.id);
    final existente = coincidencias.isEmpty ? null : coincidencias.first;
    setState(() {
      if (existente != null) {
        existente.cantidad += 1;
      } else {
        _carrito.add(_LineaCarrito(variante: variante, cantidad: 1));
      }
    });
  }

  void _quitarLinea(_LineaCarrito linea) {
    setState(() => _carrito.remove(linea));
  }

  void _cambiarCantidad(_LineaCarrito linea, double nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.remove(linea);
      } else {
        linea.cantidad = nuevaCantidad;
      }
    });
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
              cantidad: l.cantidad,
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

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();
    final productosProvider = context.watch<ProductosProvider>();
    // Solo interesan los productos que ya tienen al menos una variante registrada.
    final productosConVariantes =
        productosProvider.productos.where((p) => p.variantes.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de cliente
            if (clientesProvider.cargando)
              EstadoCargando(avisoServidorLento: clientesProvider.avisoServidorLento)
            else if (clientesProvider.error != null)
              EstadoError(
                mensaje: clientesProvider.error!,
                onReintentar: () => clientesProvider.cargar(),
              )
            else
              DropdownButtonFormField<Cliente>(
                initialValue: _clienteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                items: clientesProvider.clientes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
                    .toList(),
                onChanged: (c) => setState(() => _clienteSeleccionado = c),
              ),
            const SizedBox(height: 16),

            // Selector de estado inicial
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
            const SizedBox(height: 16),

            // Selector de variantes para agregar al carrito, agrupadas por producto base
            if (productosProvider.cargando)
              EstadoCargando(avisoServidorLento: productosProvider.avisoServidorLento)
            else if (productosProvider.error != null)
              EstadoError(
                mensaje: productosProvider.error!,
                onReintentar: () => productosProvider.cargar(),
              )
            else if (productosConVariantes.isEmpty)
              const Text('Todavía no hay variantes de producto registradas.')
            else
              SizedBox(
                height: 160,
                child: ListView(
                  children: productosConVariantes.map((producto) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(producto.nombre, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: producto.variantes
                                .map(
                                  (v) => ActionChip(
                                    avatar: const Icon(Icons.add, size: 18),
                                    label: Text('${v.nombre} (\$${v.precio.toStringAsFixed(2)})'),
                                    onPressed: () => _agregarVariante(v),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),

            // Carrito
            Expanded(
              child: _carrito.isEmpty
                  ? const Center(child: Text('Agrega productos tocando los chips de arriba'))
                  : ListView.builder(
                      itemCount: _carrito.length,
                      itemBuilder: (context, index) {
                        final linea = _carrito[index];
                        return ListTile(
                          title: Text(linea.variante.nombreCompleto()),
                          subtitle: Text(
                            '\$${linea.variante.precio.toStringAsFixed(2)} x ${linea.cantidad} = \$${linea.subtotal.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _cambiarCantidad(linea, linea.cantidad - 1),
                              ),
                              Text(linea.cantidad.toStringAsFixed(0)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _cambiarCantidad(linea, linea.cantidad + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _quitarLinea(linea),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total estimado', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
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
    );
  }
}
