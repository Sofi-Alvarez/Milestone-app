import 'package:flutter/material.dart';

import '../../../data/goal.dart';
import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';
import 'goal_card_shell.dart';

/// La etiqueta corta de estado ("En tiempo" / "Atrasado" / "Adelantado")
/// sí lleva color (neutral / error / verde). El copy de abajo
/// ("Finaliza en...", "Requiere...", "Ventaja de...") queda siempre
/// neutral — la distinción de estado no se repite ahí.
class GoalSummaryCard extends StatelessWidget {
  const GoalSummaryCard({
    super.key,
    required this.goal,
    required this.onAddSavings,
    required this.onViewDetail,
  });

  final Goal goal;
  final VoidCallback onAddSavings;
  final VoidCallback onViewDetail;

  Color _statusLabelColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (goal.pace) {
      case GoalPace.onTime:
        return colorScheme.onSurfaceVariant;
      case GoalPace.late:
        return colorScheme.error;
      case GoalPace.ahead:
        return colorScheme.tertiary;
    }
  }

  IconData get _statusIcon {
    switch (goal.pace) {
      case GoalPace.onTime:
        return Icons.event_available_outlined;
      case GoalPace.late:
        return Icons.error_outline;
      case GoalPace.ahead:
        return Icons.bolt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColor = theme.colorScheme.onSurfaceVariant;

    return GoalCardShell(
      title: goal.title,
      statusLabel: goal.paceLabel,
      statusLabelColor: _statusLabelColor(context),
      trailingValue: formatCurrency(goal.savedAmount),
      trailingLabel: 'Ahorrado',
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalProgressRow(progress: goal.progress),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            children: [
              Icon(_statusIcon, size: 16, color: noteColor),
              const SizedBox(width: HitoSpacing.xs),
              Text(
                goal.paceNote,
                style: theme.textTheme.bodySmall?.copyWith(color: noteColor),
              ),
            ],
          ),
        ],
      ),
      footer: GoalCardFooter(
        buttons: [
          TextButton.icon(
            onPressed: onAddSavings,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir ahorro'),
          ),
          TextButton.icon(
            onPressed: onViewDetail,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Ver detalle'),
          ),
        ],
      ),
    );
  }
}
