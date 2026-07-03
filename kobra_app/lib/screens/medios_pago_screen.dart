import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medios_pago_provider.dart';
import '../models/medio_pago.dart';

class MediosPagoScreen extends StatefulWidget {
  const MediosPagoScreen({super.key});

  @override
  State<MediosPagoScreen> createState() => _MediosPagoScreenState();
}

class _MediosPagoScreenState extends State<MediosPagoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediosPagoProvider>().cargar();
    });
  }

  Future<void> _agregarMedio() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo medio de pago'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ej: Mercado Pago, Cheque…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.of(context).pop(v);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (nombre != null && mounted) {
      final provider = context.read<MediosPagoProvider>();
      final ok = await provider.crear(nombre);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'No se pudo agregar')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(MedioPago medio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar medio de pago'),
        content: Text('¿Eliminar "${medio.nombre}"?'),
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
      final provider = context.read<MediosPagoProvider>();
      final ok = await provider.eliminar(medio.id);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'No se pudo eliminar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediosPagoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medios de pago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar medio',
            onPressed: _agregarMedio,
          ),
        ],
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => provider.cargar(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: provider.medios.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final medio = provider.medios[index];
                    return ListTile(
                      title: Text(
                        medio.nombre,
                        style: TextStyle(
                          color: medio.activo
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: medio.esDefault
                          ? const Text('Predeterminado')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: medio.activo,
                            onChanged: (_) => provider.toggleActivo(medio.id),
                          ),
                          if (!medio.esDefault)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmarEliminar(medio),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
