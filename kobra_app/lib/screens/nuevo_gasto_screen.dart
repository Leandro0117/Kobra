import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/proveedor.dart';
import '../models/insumo.dart';
import '../models/detalle_gasto.dart';
import '../models/categoria_gasto.dart';
import '../providers/proveedores_provider.dart';
import '../providers/insumos_provider.dart';
import '../providers/gastos_provider.dart';
import '../utils/formato.dart';
import '../widgets/estado_carga.dart';

class _LineaCarritoGasto {
  final Insumo insumo;
  double cantidad;
  double precioUnitario;

  _LineaCarritoGasto({
    required this.insumo,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class NuevoGastoScreen extends StatefulWidget {
  const NuevoGastoScreen({super.key});

  @override
  State<NuevoGastoScreen> createState() => _NuevoGastoScreenState();
}

class _NuevoGastoScreenState extends State<NuevoGastoScreen> {
  Proveedor? _proveedorSeleccionado;
  CategoriaGasto _categoriaSeleccionada = CategoriaGasto.INSUMOS;
  final List<_LineaCarritoGasto> _carrito = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedoresProvider>().cargar();
      context.read<InsumosProvider>().cargar();
    });
  }

  double get _total => _carrito.fold(0, (sum, linea) => sum + linea.subtotal);

  Future<void> _mostrarDialogoLinea(Insumo insumo, {_LineaCarritoGasto? existente}) async {
    final cantidadController = TextEditingController(
      text: existente != null ? existente.cantidad.toString() : '1',
    );
    final precioController = TextEditingController(
      text: existente != null
          ? existente.precioUnitario.toString()
          : (insumo.precio != null ? insumo.precio.toString() : ''),
    );
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insumo.nombre),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: cantidadController,
                decoration: InputDecoration(
                  labelText: insumo.unidad != null
                      ? 'Cantidad (${unidadInsumoLabel(insumo.unidad!)})'
                      : 'Cantidad',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Cantidad inválida';
                  return null;
                },
              ),
              TextFormField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio unitario pagado'),
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
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (guardar != true) return;

    final cantidad = double.parse(cantidadController.text);
    final precioUnitario = double.parse(precioController.text);

    setState(() {
      if (existente != null) {
        existente.cantidad = cantidad;
        existente.precioUnitario = precioUnitario;
      } else {
        _carrito.add(
          _LineaCarritoGasto(insumo: insumo, cantidad: cantidad, precioUnitario: precioUnitario),
        );
      }
    });
  }

  void _quitarLinea(_LineaCarritoGasto linea) {
    setState(() => _carrito.remove(linea));
  }

  Future<void> _guardarGasto() async {
    if (_proveedorSeleccionado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un proveedor')));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agrega al menos un insumo')));
      return;
    }

    setState(() => _guardando = true);

    final detalles = _carrito
        .map((l) => DetalleGasto(
              insumoId: l.insumo.id,
              cantidad: l.cantidad,
              precioUnitario: l.precioUnitario,
            ))
        .toList();

    final gastosProvider = context.read<GastosProvider>();
    final gasto = await gastosProvider.crear(
      proveedorId: _proveedorSeleccionado!.id,
      categoria: _categoriaSeleccionada,
      detalles: detalles,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (gasto != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gasto registrado correctamente')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gastosProvider.error ?? 'No se pudo registrar el gasto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresProvider = context.watch<ProveedoresProvider>();
    final insumosProvider = context.watch<InsumosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de proveedor
            if (proveedoresProvider.cargando)
              EstadoCargando(avisoServidorLento: proveedoresProvider.avisoServidorLento)
            else if (proveedoresProvider.error != null)
              EstadoError(
                mensaje: proveedoresProvider.error!,
                onReintentar: () => proveedoresProvider.cargar(),
              )
            else
              DropdownButtonFormField<Proveedor>(
                initialValue: _proveedorSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Proveedor',
                  border: OutlineInputBorder(),
                ),
                items: proveedoresProvider.proveedores
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.nombre)))
                    .toList(),
                onChanged: (p) => setState(() => _proveedorSeleccionado = p),
              ),
            const SizedBox(height: 16),

            // Selector de categoría
            DropdownButtonFormField<CategoriaGasto>(
              initialValue: _categoriaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: CategoriaGasto.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(categoriaGastoLabel(c))))
                  .toList(),
              onChanged: (c) => setState(() => _categoriaSeleccionada = c!),
            ),
            const SizedBox(height: 16),

            // Selector de insumos para agregar al carrito
            if (insumosProvider.cargando)
              EstadoCargando(avisoServidorLento: insumosProvider.avisoServidorLento)
            else if (insumosProvider.error != null)
              EstadoError(
                mensaje: insumosProvider.error!,
                onReintentar: () => insumosProvider.cargar(),
              )
            else if (insumosProvider.insumos.isEmpty)
              const Text('Todavía no hay insumos registrados.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insumosProvider.insumos
                    .map(
                      (i) => ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(i.nombre),
                        onPressed: () => _mostrarDialogoLinea(i),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            const Divider(),

            // Carrito
            Expanded(
              child: _carrito.isEmpty
                  ? const Center(child: Text('Agrega insumos tocando los chips de arriba'))
                  : ListView.builder(
                      itemCount: _carrito.length,
                      itemBuilder: (context, index) {
                        final linea = _carrito[index];
                        return ListTile(
                          title: Text(linea.insumo.nombre),
                          subtitle: Text(
                            '${formatPrecio(linea.precioUnitario)} x ${formatMonto(linea.cantidad)} = ${formatPrecio(linea.subtotal)}',
                          ),
                          onTap: () => _mostrarDialogoLinea(linea.insumo, existente: linea),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _quitarLinea(linea),
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
              onPressed: _guardando ? null : _guardarGasto,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
