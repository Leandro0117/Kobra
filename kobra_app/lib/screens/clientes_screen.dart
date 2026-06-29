import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/clientes_provider.dart';
import '../widgets/estado_carga.dart';
import 'detalle_cliente_screen.dart';

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

  Future<void> _mostrarFormularioCliente({Cliente? existente}) async {
    final nombreController = TextEditingController(text: existente?.nombre ?? '');
    final telefonoController = TextEditingController(text: existente?.telefono ?? '');
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existente == null ? 'Nuevo cliente' : 'Editar cliente'),
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
      final clientesProvider = context.read<ClientesProvider>();
      final nombre = nombreController.text.trim();
      final telefono = telefonoController.text.trim();
      final ok = existente == null
          ? await clientesProvider.crear(nombre, telefono)
          : await clientesProvider.actualizar(existente.id, nombre, telefono);

      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clientesProvider.error ?? 'No se pudo guardar el cliente')),
        );
      }
    }
  }

  Future<void> _confirmarEliminarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminar "${cliente.nombre}"? Si tiene ventas asociadas no se podrá eliminar.',
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
      final clientesProvider = context.read<ClientesProvider>();
      final ok = await clientesProvider.eliminar(cliente.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clientesProvider.error ?? 'No se pudo eliminar el cliente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();
    final esAdmin = context.watch<AuthProvider>().usuario?.rol == Rol.ADMIN;

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCliente(),
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
                  trailing: esAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _mostrarFormularioCliente(existente: cliente),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmarEliminarCliente(cliente),
                            ),
                          ],
                        )
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetalleClienteScreen(clienteId: cliente.id),
                    ),
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
