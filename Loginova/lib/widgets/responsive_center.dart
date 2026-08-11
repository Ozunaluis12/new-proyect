import 'package:flutter/material.dart';

/// Centra su contenido y le limita el ancho máximo en pantallas anchas
/// (escritorio/web): sin esto, un formulario o una tarjeta de detalle
/// diseñados para celular quedan estirados de borde a borde en una ventana
/// de +1200px, con los campos larguísimos y el texto luciendo
/// desproporcionado. En celular (ancho <= [maxWidth]) no cambia nada
/// respecto al layout normal, porque el ancho de pantalla nunca alcanza
/// el límite.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
