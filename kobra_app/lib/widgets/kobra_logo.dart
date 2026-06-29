import 'package:flutter/material.dart';

/// Logotipo completo de Kobra. Usa la variante en negativo (blanco) cuando
/// se muestra sobre un fondo oscuro.
class KobraLogo extends StatelessWidget {
  const KobraLogo({super.key, this.height = 40, this.negative = false});

  final double height;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      negative ? 'assets/Logo_Kobra_Negative.png' : 'assets/Logo Kobra.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
