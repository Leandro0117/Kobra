import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../models/variante.dart';
import '../providers/auth_provider.dart';
import '../providers/productos_provider.dart';
import '../widgets/estado_carga.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargar();
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
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Precio inválido';
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

      final ok = existente == null
          ? await productosProvider.agregarVariante(producto.id, nombre, precio)
          : await productosProvider.actualizarVariante(
              producto.id,
              existente.id,
              nombre: nombre,
              precio: precio,
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

  @override
  Widget build(BuildContext context) {
    final productosProvider = context.watch<ProductosProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: esAdmin
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
                return ExpansionTile(
                  title: Text(producto.nombre),
                  subtitle: Text('${producto.variantes.length} variante(s)'),
                  trailing: esAdmin
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _mostrarFormularioProducto(existente: producto),
                        )
                      : null,
                  children: [
                    ...producto.variantes.map(
                      (v) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 32, right: 16),
                        title: Text(v.nombre),
                        subtitle: Text('\$${v.precio.toStringAsFixed(2)}'),
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
