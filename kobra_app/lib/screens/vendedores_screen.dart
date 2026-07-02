import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

class VendedoresScreen extends StatefulWidget {
  const VendedoresScreen({super.key});

  @override
  State<VendedoresScreen> createState() => _VendedoresScreenState();
}

class _VendedoresScreenState extends State<VendedoresScreen> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _vendedores = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _authService.listarVendedores();
      if (mounted) setState(() => _vendedores = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irACrear() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _CrearVendedorScreen()),
    );
    _cargar();
  }

  Future<void> _irADetalle(Map<String, dynamic> vendedor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _DetalleVendedorScreen(vendedor: vendedor)),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendedores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irACrear,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Agregar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _vendedores.isEmpty
                  ? const Center(child: Text('No hay vendedores registrados.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vendedores.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final v = _vendedores[i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(v['nombre'] as String),
                          subtitle: Text(v['email'] as String),
                          contentPadding: EdgeInsets.zero,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _irADetalle(v),
                        );
                      },
                    ),
    );
  }
}

// ── Detalle / edición ────────────────────────────────────────────────────────

class _DetalleVendedorScreen extends StatefulWidget {
  final Map<String, dynamic> vendedor;
  const _DetalleVendedorScreen({required this.vendedor});

  @override
  State<_DetalleVendedorScreen> createState() => _DetalleVendedorScreenState();
}

class _DetalleVendedorScreenState extends State<_DetalleVendedorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _guardando = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.vendedor['nombre'] as String);
    _emailController = TextEditingController(text: widget.vendedor['email'] as String);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _authService.actualizarVendedor(
        id: widget.vendedor['id'] as int,
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar vendedor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa el email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  hintText: 'Dejar vacío para no cambiarla',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v != null && v.isNotEmpty && v.length < 6)
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Crear vendedor ───────────────────────────────────────────────────────────

class _CrearVendedorScreen extends StatefulWidget {
  const _CrearVendedorScreen();

  @override
  State<_CrearVendedorScreen> createState() => _CrearVendedorScreenState();
}

class _CrearVendedorScreenState extends State<_CrearVendedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _guardando = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _authService.crearVendedor(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo vendedor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa el email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Agregar vendedor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
