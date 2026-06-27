import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clientes_provider.dart';
import '../widgets/estado_carga.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().cargar();
    });
  }

  Future<void> _mostrarFormularioNuevoCliente() async {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo cliente'),
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
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true && mounted) {
      final ok = await context.read<ClientesProvider>().crear(
            nombreController.text.trim(),
            telefonoController.text.trim(),
          );
      if (!mounted) return;
      if (!ok) {
        final error = context.read<ClientesProvider>().error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error ?? 'No se pudo crear el cliente')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevoCliente,
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (clientesProvider.cargando) {
            return EstadoCargando(avisoServidorLento: clientesProvider.avisoServidorLento);
          }
          if (clientesProvider.error != null) {
            return EstadoError(
              mensaje: clientesProvider.error!,
              onReintentar: () => clientesProvider.cargar(),
            );
          }
          if (clientesProvider.clientes.isEmpty) {
            return const Center(child: Text('Todavía no hay clientes registrados.'));
          }
          return RefreshIndicator(
            onRefresh: clientesProvider.cargar,
            child: ListView.separated(
              itemCount: clientesProvider.clientes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cliente = clientesProvider.clientes[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(cliente.nombre),
                  subtitle: cliente.telefono != null ? Text(cliente.telefono!) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
