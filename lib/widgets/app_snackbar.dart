import 'package:flutter/material.dart';

/// Snackbar estándar de la app: 3 segundos en pantalla (o hasta que el
/// usuario lo descarte, lo que ocurra primero — comportamiento nativo
/// de [SnackBar] al deslizarlo).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      backgroundColor:
          isError ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
