import 'package:flutter/material.dart';

/// Spinner con mensaje. Si [avisoServidorLento] es true, cambia el texto
/// para avisar que el backend (Render free tier) puede estar despertando.
class EstadoCargando extends StatelessWidget {
  final bool avisoServidorLento;

  const EstadoCargando({super.key, this.avisoServidorLento = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              avisoServidorLento
                  ? 'Conectando con el servidor, puede tardar unos segundos...'
                  : 'Cargando...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje de error con botón opcional de reintentar.
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const EstadoError({super.key, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
