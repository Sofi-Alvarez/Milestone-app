import 'package:flutter/material.dart';

/// Envoltorio de `showModalBottomSheet` con los parámetros estándar que
/// los 8 sheets de la app repetían a mano (`isScrollControlled: true`,
/// `backgroundColor: Colors.transparent` — cada sheet pinta su propio
/// contenedor redondeado arriba). Antes, si se decidía cambiar ese
/// comportamiento base, había que tocar 8 archivos; ahora es uno solo.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    builder: builder,
  );
}
