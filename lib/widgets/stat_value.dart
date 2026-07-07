import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card chica de "label + valor" — reemplaza las variantes que antes
/// vivían por separado en cada pantalla (Home, Presupuestos, el wizard
/// de creación), cada una con su propio padding/fondo/peso de fuente
/// para mostrar exactamente el mismo tipo de dato.
class StatValue extends StatelessWidget {
  const StatValue({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.background,
    this.foreground,
    this.valueColor,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Fondo de la card. Por defecto, primaryContainer (mismo tono lavanda
  /// que la hero card de ahorro total, para que todas las stat cards se
  /// vean consistentes con esa jerarquía visual).
  final Color? background;

  /// Color de label y valor cuando [background] es un color con
  /// contenedor propio (ej. `primaryContainer` necesita `onPrimaryContainer`
  /// para ambos textos, no solo `onSurfaceVariant`).
  final Color? foreground;

  /// Override puntual del color del valor (ej. rojo si el número es
  /// negativo) — independiente de [foreground].
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = foreground ?? theme.colorScheme.onSurfaceVariant;
    final content = Container(
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? foreground,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: content,
    );
  }
}
