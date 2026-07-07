import 'dart:async';

import 'package:flutter/material.dart';

/// Toast propio en vez del `SnackBar` de Material para los avisos
/// informativos — el `SnackBar` de Flutter pausa su temporizador
/// mientras el mouse queda posicionado encima (accesibilidad, WCAG
/// 2.2.1), lo cual en desktop lo dejaba trabado indefinidamente si el
/// cursor quedaba cerca después de tocar un botón. Este toast se
/// autodescarta a los 3s pase lo que pase con el mouse.
class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.onDismissed,
    required this.bottomOffset,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final VoidCallback onDismissed;
  final double bottomOffset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast> {
  bool _visible = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // Un frame para que el fade-in se note, no aparecer ya opaco.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 200), widget.onDismissed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottomOffset + bottomSafeArea,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                ),
                if (widget.actionLabel != null) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      widget.onAction?.call();
                      _dismiss();
                    },
                    child: Text(widget.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

OverlayEntry? _currentToast;

/// Alto aproximado de [HitoBottomNavBar] + el FAB central que flota por
/// encima — el offset por default despeja esa zona para que el toast
/// quede justo arriba de los CTA en vez de taparlos.
const _defaultBottomOffset = 88.0;

/// Muestra un toast informativo que se autodescarta a los 3s sin
/// importar dónde esté el mouse. Reemplaza cualquier toast anterior en
/// pantalla en vez de encolarse. [bottomOffset] ajusta qué tan arriba
/// del borde inferior aparece — subilo si la pantalla tiene un CTA fijo
/// más alto que la bottom nav estándar.
void showAppToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  double bottomOffset = _defaultBottomOffset,
}) {
  _currentToast?.remove();
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AppToast(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      bottomOffset: bottomOffset,
      onDismissed: () {
        entry.remove();
        if (identical(_currentToast, entry)) _currentToast = null;
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

/// Snackbar de error — se queda hasta que el usuario la descarte a
/// propósito (deslizando o con "Cerrar"). A diferencia del toast de
/// arriba, sí usamos el `SnackBar` real acá porque su comportamiento de
/// quedarse fijo es justamente lo que queremos.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!isError) {
    showAppToast(context, message);
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(days: 1),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Cerrar',
        textColor: Theme.of(context).colorScheme.onError,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ),
  );
}
