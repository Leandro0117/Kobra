import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../models/variante.dart';
import '../providers/auth_provider.dart';
import '../providers/productos_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  bool _modoSeleccion = false;
  final Set<int> _seleccionados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargar();
    });
  }

  void _activarModoSeleccion() {
    setState(() => _modoSeleccion = true);
  }

  void _salirModoSeleccion() {
    setState(() {
      _modoSeleccion = false;
      _seleccionados.clear();
    });
  }

  void _alternarSeleccion(int productoId) {
    setState(() {
      if (_seleccionados.contains(productoId)) {
        _seleccionados.remove(productoId);
      } else {
        _seleccionados.add(productoId);
      }
    });
  }

  Future<void> _mostrarFormularioProducto({Producto? existente}) async {
    final nombreController = TextEditingController(text: existente?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existente == null ? 'Nuevo producto' : 'Renombrar producto'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre (ej. Yogurt griego)'),
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true && mounted) {
      final productosProvider = context.read<ProductosProvider>();
      final nombre = nombreController.text.trim();
      final ok = existente == null
          ? await productosProvider.crear(nombre)
          : await productosProvider.actualizar(existente.id, nombre);

      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productosProvider.error ?? 'No se pudo guardar el producto')),
        );
      }
    }
  }

  Future<void> _mostrarFormularioVariante(Producto producto, {Variante? existente}) async {
    final nombreController = TextEditingController(text: existente?.nombre ?? '');
    final precioController = TextEditingController(
      text: existente != null ? existente.precio.toString() : '',
    );
    final costoController = TextEditingController(
      text: existente?.costo != null ? existente!.costo.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existente == null ? 'Nueva variante' : 'Editar variante'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre (ej. 250g mermelada de fresa)',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio de venta al público'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Precio inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: costoController,
                decoration: const InputDecoration(
                  labelText: 'Costo (opcional, para calcular ganancia)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Costo inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true && mounted) {
      final productosProvider = context.read<ProductosProvider>();
      final nombre = nombreController.text.trim();
      final precio = double.parse(precioController.text);
      final costo = costoController.text.trim().isEmpty
          ? null
          : double.parse(costoController.text.trim());

      final ok = existente == null
          ? await productosProvider.agregarVariante(producto.id, nombre, precio, costo: costo)
          : await productosProvider.actualizarVariante(
              producto.id,
              existente.id,
              nombre: nombre,
              precio: precio,
              costo: costo,
            );

      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productosProvider.error ?? 'No se pudo guardar la variante')),
        );
      }
    }
  }

  Future<void> _confirmarEliminarVariante(Producto producto, Variante variante) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar variante'),
        content: Text('¿Eliminar "${variante.nombre}"?'),
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

    if (confirmar == true && mounted) {
      final productosProvider = context.read<ProductosProvider>();
      final ok = await productosProvider.eliminarVariante(producto.id, variante.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productosProvider.error ?? 'No se pudo eliminar la variante')),
        );
      }
    }
  }

  /// Texto de advertencia cuando el/los producto(s) a eliminar tienen variantes:
  /// se borrarán junto con el producto (a menos que alguna ya tenga ventas).
  String _advertenciaVariantes(List<Producto> productos) {
    final totalVariantes = productos.fold<int>(0, (s, p) => s + p.variantes.length);
    if (totalVariantes == 0) return '';
    final conVariantes = productos.where((p) => p.variantes.isNotEmpty).length;
    return productos.length == 1
        ? '\n\nEste producto tiene ${productos.first.variantes.length} variante(s); '
            'se eliminarán junto con él (salvo que alguna ya tenga ventas registradas, '
            'en cuyo caso no se podrá eliminar nada).'
        : '\n\n$conVariantes de ellos tienen variantes ($totalVariantes en total); '
            'se eliminarán junto con su producto (salvo que alguna ya tenga ventas registradas, '
            'en cuyo caso ese producto en particular no se podrá eliminar).';
  }

  Future<void> _confirmarEliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${producto.nombre}"?${_advertenciaVariantes([producto])}',
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

    if (confirmar == true && mounted) {
      final productosProvider = context.read<ProductosProvider>();
      final ok = await productosProvider.eliminar(producto.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productosProvider.error ?? 'No se pudo eliminar el producto')),
        );
      }
    }
  }

  Future<void> _confirmarEliminarSeleccionados(List<Producto> productosSeleccionados) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar productos seleccionados'),
        content: Text(
          '¿Eliminar ${productosSeleccionados.length} producto(s)?'
          '${_advertenciaVariantes(productosSeleccionados)}',
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

    final productosProvider = context.read<ProductosProvider>();
    final ids = productosSeleccionados.map((p) => p.id).toList();
    final resultados = await productosProvider.eliminarVarios(ids);
    if (!mounted) return;

    final exitosos = resultados.entries.where((e) => e.value == null).length;
    final fallidos = resultados.entries.where((e) => e.value != null).toList();

    String mensaje;
    if (fallidos.isEmpty) {
      mensaje = 'Se eliminaron $exitosos producto(s).';
    } else {
      final mensajesUnicos = fallidos.map((e) => e.value).toSet().join(' ');
      mensaje = '$exitosos eliminado(s). ${fallidos.length} no se pudo(eron) eliminar: '
          '$mensajesUnicos';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    _salirModoSeleccion();
  }

  @override
  Widget build(BuildContext context) {
    final productosProvider = context.watch<ProductosProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;
    final productosSeleccionados =
        productosProvider.productos.where((p) => _seleccionados.contains(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoSeleccion ? '${_seleccionados.length} seleccionado(s)' : 'Productos'),
        leading: _modoSeleccion
            ? IconButton(icon: const Icon(Icons.close), onPressed: _salirModoSeleccion)
            : null,
        actions: [
          if (_modoSeleccion)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar seleccionados',
              onPressed: productosSeleccionados.isEmpty
                  ? null
                  : () => _confirmarEliminarSeleccionados(productosSeleccionados),
            )
          else if (esAdmin)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Seleccionar varios',
              onPressed: _activarModoSeleccion,
            ),
        ],
      ),
      floatingActionButton: (esAdmin && !_modoSeleccion)
          ? FloatingActionButton(
              onPressed: () => _mostrarFormularioProducto(),
              tooltip: 'Nuevo producto',
              child: const Icon(Icons.add),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (productosProvider.cargando) {
            return EstadoCargando(avisoServidorLento: productosProvider.avisoServidorLento);
          }
          if (productosProvider.error != null) {
            return EstadoError(
              mensaje: productosProvider.error!,
              onReintentar: () => productosProvider.cargar(),
            );
          }
          if (productosProvider.productos.isEmpty) {
            return const Center(child: Text('Todavía no hay productos registrados.'));
          }
          return RefreshIndicator(
            onRefresh: productosProvider.cargar,
            child: ListView.builder(
              itemCount: productosProvider.productos.length,
              itemBuilder: (context, index) {
                final producto = productosProvider.productos[index];
                final seleccionado = _seleccionados.contains(producto.id);
                return ExpansionTile(
                  leading: _modoSeleccion
                      ? Checkbox(
                          value: seleccionado,
                          onChanged: (_) => _alternarSeleccion(producto.id),
                        )
                      : null,
                  title: Text(producto.nombre),
                  subtitle: Text('${producto.variantes.length} variante(s)'),
                  trailing: _modoSeleccion
                      ? null
                      : esAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _mostrarFormularioProducto(existente: producto),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmarEliminarProducto(producto),
                                ),
                              ],
                            )
                          : null,
                  children: [
                    ...producto.variantes.map(
                      (v) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 32, right: 16),
                        title: Text(v.nombre),
                        subtitle: Text(
                          v.costo != null
                              ? '${formatPrecio(v.precio)} · costo ${formatPrecio(v.costo!)} '
                                  '· ganancia ${formatPrecio(v.ganancia!)} (${v.margenPorcentaje!.toStringAsFixed(0)}%)'
                              : formatPrecio(v.precio),
                        ),
                        trailing: esAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _mostrarFormularioVariante(producto, existente: v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmarEliminarVariante(producto, v),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (esAdmin)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _mostrarFormularioVariante(producto),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar variante'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
