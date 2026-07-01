import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fila de acción con ícono, label, y estado a la derecha — reemplaza
/// las dos copias que existían por separado (Perfil y Presupuestos),
/// cada una con su propia mitad del comportamiento (texto secundario
/// vs. spinner de carga).
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Texto secundario a la derecha del label (ej. "Español").
  final String? trailing;

  final Color? labelColor;

  /// Reemplaza el chevron por un spinner y deshabilita el tap mientras
  /// la acción escribe en el backend.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HitoSpacing.md,
          vertical: HitoSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: labelColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: HitoSpacing.xs),
            if (busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
