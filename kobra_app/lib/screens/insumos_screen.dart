import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insumo.dart';
import '../utils/formato.dart';
import '../providers/insumos_provider.dart';
import '../widgets/estado_carga.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumosProvider>().cargar();
    });
  }

  Future<void> _mostrarFormularioNuevoInsumo() async {
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    UnidadInsumo? unidadSeleccionada;
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo insumo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UnidadInsumo?>(
                  initialValue: unidadSeleccionada,
                  decoration: const InputDecoration(labelText: 'Unidad (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin unidad')),
                    ...UnidadInsumo.values.map(
                      (u) => DropdownMenuItem(value: u, child: Text(unidadInsumoLabel(u))),
                    ),
                  ],
                  onChanged: (u) => setDialogState(() => unidadSeleccionada = u),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio de referencia (opcional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return 'Precio inválido';
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
      ),
    );

    if (guardar == true && mounted) {
      final precio = precioController.text.trim().isEmpty
          ? null
          : double.tryParse(precioController.text.trim());
      final ok = await context.read<InsumosProvider>().crear(
            nombreController.text.trim(),
            unidadSeleccionada,
            precio,
          );
      if (!mounted) return;
      if (!ok) {
        final error = context.read<InsumosProvider>().error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error ?? 'No se pudo crear el insumo')));
      }
    }
  }

  Future<void> _confirmarEliminar(Insumo insumo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar insumo'),
        content: Text('¿Eliminar "${insumo.nombre}"?'),
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
      final insumosProvider = context.read<InsumosProvider>();
      final ok = await insumosProvider.eliminar(insumo.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(insumosProvider.error ?? 'No se pudo eliminar el insumo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumosProvider = context.watch<InsumosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Insumos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevoInsumo,
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (insumosProvider.cargando) {
            return EstadoCargando(avisoServidorLento: insumosProvider.avisoServidorLento);
          }
          if (insumosProvider.error != null) {
            return EstadoError(
              mensaje: insumosProvider.error!,
              onReintentar: () => insumosProvider.cargar(),
            );
          }
          if (insumosProvider.insumos.isEmpty) {
            return const Center(child: Text('Todavía no hay insumos registrados.'));
          }
          return RefreshIndicator(
            onRefresh: insumosProvider.cargar,
            child: ListView.separated(
              itemCount: insumosProvider.insumos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final insumo = insumosProvider.insumos[index];
                return ListTile(
                  leading: const Icon(Icons.inventory_outlined),
                  title: Text(insumo.nombre),
                  subtitle: (insumo.unidad != null || insumo.precio != null)
                      ? Text([
                          if (insumo.unidad != null) unidadInsumoLabel(insumo.unidad!),
                          if (insumo.precio != null) formatPrecio(insumo.precio!),
                        ].join(' · '))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmarEliminar(insumo),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
