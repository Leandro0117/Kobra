import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/negocio.dart';
import '../providers/negocio_provider.dart';

/// Formulario para registrar o editar la info del negocio. Cuando [esEdicion]
/// es false se muestra como paso obligatorio tras crear el usuario admin (sin
/// botón para salir); cuando es true se abre desde Home y se puede cancelar.
class RegistroNegocioScreen extends StatefulWidget {
  final bool esEdicion;

  const RegistroNegocioScreen({super.key, this.esEdicion = false});

  @override
  State<RegistroNegocioScreen> createState() => _RegistroNegocioScreenState();
}

class _RegistroNegocioScreenState extends State<RegistroNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _monedaController;

  @override
  void initState() {
    super.initState();
    final negocio = context.read<NegocioProvider>().negocio;
    _nombreController = TextEditingController(text: negocio?.nombre ?? '');
    _direccionController = TextEditingController(text: negocio?.direccion ?? '');
    _telefonoController = TextEditingController(text: negocio?.telefono ?? '');
    _monedaController = TextEditingController(text: negocio?.moneda ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _monedaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final negocioProvider = context.read<NegocioProvider>();
    final negocio = Negocio(
      nombre: _nombreController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      moneda: _monedaController.text.trim(),
    );

    final exito = await negocioProvider.guardar(negocio);

    if (!mounted) return;
    if (exito) {
      if (widget.esEdicion) Navigator.of(context).pop();
    } else if (negocioProvider.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(negocioProvider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final negocioProvider = context.watch<NegocioProvider>();

    return Scaffold(
      appBar: widget.esEdicion ? AppBar(title: const Text('Datos del negocio')) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.esEdicion) ...[
                      Icon(
                        Icons.storefront_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cuéntanos de tu negocio',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                    ],
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del negocio *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Ingresa el nombre del negocio'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monedaController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Moneda *',
                        hintText: 'Ej. USD, MXN, COP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Ingresa la moneda'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: negocioProvider.cargando ? null : _guardar,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: negocioProvider.cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.esEdicion ? 'Guardar' : 'Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
