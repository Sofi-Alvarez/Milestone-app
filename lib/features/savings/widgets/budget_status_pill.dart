import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../budget_progress.dart';

/// Etiqueta corta de estado de una categoría/presupuesto — mismo
/// patrón visual en toda la feature de Presupuestos: pastilla chica,
/// texto en mayúscula de peso medio, color según [health].
class BudgetStatusPill extends StatelessWidget {
  const BudgetStatusPill({super.key, required this.label, required this.health});

  final String label;
  final BudgetHealthStatus health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (health) {
      BudgetHealthStatus.exceeded => (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer),
      BudgetHealthStatus.nearLimit => (HitoColors.warningContainerLight, HitoColors.warningLight),
      BudgetHealthStatus.onTrack => (recessedColor(theme), theme.colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

Color progressColorFor(BuildContext context, BudgetHealthStatus health) {
  final theme = Theme.of(context);
  return switch (health) {
    BudgetHealthStatus.exceeded => theme.colorScheme.error,
    BudgetHealthStatus.nearLimit => HitoColors.warningLight,
    BudgetHealthStatus.onTrack => theme.colorScheme.primary,
  };
}
