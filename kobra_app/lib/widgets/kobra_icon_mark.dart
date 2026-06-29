import 'package:flutter/material.dart';

/// Ícono de marca de Kobra: fondo sólido de marca con el ícono minimal
/// encima, centrado horizontalmente y con el borde inferior del PNG
/// coincidiendo con el borde inferior del contenedor.
class KobraIconMark extends StatelessWidget {
  const KobraIconMark({super.key, this.size = 96, this.borderRadius});

  final double size;
  final BorderRadius? borderRadius;

  static const Color colorFondo = Color(0xFF454E87);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
      child: Container(
        width: size,
        height: size,
        color: colorFondo,
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.symmetric(horizontal: size * 0.15),
        child: Image.asset('assets/Kobra_Icon_App.png', fit: BoxFit.contain),
      ),
    );
  }
}
