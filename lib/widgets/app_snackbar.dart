import 'package:flutter/material.dart';

/// Snackbar estándar de la app. Los informativos se auto-dismissean a
/// los 3s; los de error se quedan hasta que el usuario los descarte
/// (deslizando o con el botón "Cerrar") — un error no debería poder
/// perderse por desaparecer solo.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: isError ? const Duration(days: 1) : const Duration(seconds: 3),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      action: isError
          ? SnackBarAction(
              label: 'Cerrar',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            )
          : null,
    ),
  );
}
