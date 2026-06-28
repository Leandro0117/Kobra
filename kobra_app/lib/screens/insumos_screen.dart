import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insumo.dart';
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
    final unidadController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo insumo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Azúcar)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: unidadController,
                decoration: const InputDecoration(
                  labelText: 'Unidad (opcional, ej. kg, litro, unidad)',
                ),
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
      final ok = await context.read<InsumosProvider>().crear(
            nombreController.text.trim(),
            unidadController.text.trim(),
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
                  subtitle: insumo.unidad != null ? Text(insumo.unidad!) : null,
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
