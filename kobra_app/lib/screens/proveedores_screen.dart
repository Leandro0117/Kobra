import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/proveedor.dart';
import '../providers/proveedores_provider.dart';
import '../widgets/estado_carga.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedoresProvider>().cargar();
    });
  }

  Future<void> _mostrarFormulario({Proveedor? existente}) async {
    final nombreController = TextEditingController(text: existente?.nombre);
    final telefonoController = TextEditingController(text: existente?.telefono ?? '');
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existente == null ? 'Nuevo proveedor' : 'Editar proveedor'),
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
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
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
      final provider = context.read<ProveedoresProvider>();
      final nombre = nombreController.text.trim();
      final telefono = telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim();
      final bool ok;
      if (existente == null) {
        ok = await provider.crear(nombre, telefono);
      } else {
        ok = await provider.actualizar(existente.id, nombre, telefono);
      }
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<ProveedoresProvider>().error ?? 'No se pudo guardar el proveedor')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Proveedor proveedor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${proveedor.nombre}"?'),
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
      final proveedoresProvider = context.read<ProveedoresProvider>();
      final ok = await proveedoresProvider.eliminar(proveedor.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(proveedoresProvider.error ?? 'No se pudo eliminar el proveedor')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresProvider = context.watch<ProveedoresProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (proveedoresProvider.cargando) {
            return EstadoCargando(avisoServidorLento: proveedoresProvider.avisoServidorLento);
          }
          if (proveedoresProvider.error != null) {
            return EstadoError(
              mensaje: proveedoresProvider.error!,
              onReintentar: () => proveedoresProvider.cargar(),
            );
          }
          if (proveedoresProvider.proveedores.isEmpty) {
            return const Center(child: Text('Todavía no hay proveedores registrados.'));
          }
          return RefreshIndicator(
            onRefresh: proveedoresProvider.cargar,
            child: ListView.separated(
              itemCount: proveedoresProvider.proveedores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final proveedor = proveedoresProvider.proveedores[index];
                return ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(proveedor.nombre),
                  subtitle: proveedor.telefono != null ? Text(proveedor.telefono!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _mostrarFormulario(existente: proveedor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmarEliminar(proveedor),
                      ),
                    ],
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
