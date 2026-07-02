import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthProvider>().usuario!;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Mi cuenta', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _InfoRow(label: 'Nombre', valor: usuario.nombre),
                  const Divider(height: 24),
                  _InfoRow(label: 'Email', valor: usuario.email),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Rol',
                    valor: usuario.rol == Rol.ADMIN ? 'Administrador' : 'Vendedor',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Seguridad', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _CambiarPasswordScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cambiar contraseña ────────────────────────────────────────────────────────

class _CambiarPasswordScreen extends StatefulWidget {
  const _CambiarPasswordScreen();

  @override
  State<_CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<_CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _authService = AuthService();

  bool _guardando = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await _authService.cambiarPassword(
        passwordActual: _actualController.text,
        passwordNueva: _nuevaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
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
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _actualController,
                obscureText: _obscureActual,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureActual ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureActual = !_obscureActual),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nuevaController,
                obscureText: _obscureNueva,
                decoration: InputDecoration(
                  labelText: 'Contraseña nueva',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNueva ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNueva = !_obscureNueva),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la contraseña nueva';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarController,
                obscureText: _obscureConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña nueva',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmar ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmar = !_obscureConfirmar),
                  ),
                ),
                validator: (v) => v != _nuevaController.text
                    ? 'Las contraseñas no coinciden'
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
                    : const Text('Cambiar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget auxiliar ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(valor, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
