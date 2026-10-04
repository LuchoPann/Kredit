import 'package:flutter/material.dart';

/// Ruta con slide horizontal de izquierda a derecha — mismo feeling que el
/// asistente de creación de créditos. Úsala en lugar de [MaterialPageRoute]
/// para cualquier pantalla que se abre desde la vista de configuración.
PageRouteBuilder<T> slidePageRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      // Pantalla entrante desliza desde la derecha.
      final slideIn = Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(curved);
      // Pantalla saliente se desplaza levemente a la izquierda (parallax sutil).
      final slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.25, 0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: slideOut,
        child: SlideTransition(position: slideIn, child: child),
      );
    },
  );
}
