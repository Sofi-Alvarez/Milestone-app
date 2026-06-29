import 'package:flutter/material.dart';

import '../../../data/goal.dart';
import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';
import 'goal_card_shell.dart';

class PausedGoalCard extends StatelessWidget {
  const PausedGoalCard({
    super.key,
    required this.goal,
    required this.onResume,
    required this.onViewDetail,
  });

  final Goal goal;
  final VoidCallback onResume;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pausedColor = isDark ? HitoColors.warningDark : HitoColors.warningLight;
    final noteColor = theme.colorScheme.onSurfaceVariant;

    return GoalCardShell(
      title: goal.title,
      statusLabel: 'Pausada',
      statusLabelColor: pausedColor,
      trailingValue: formatCurrency(goal.savedAmount),
      trailingLabel: 'Ahorrado',
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalProgressRow(progress: goal.progress),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            children: [
              Text(
                'Monto de meta: ',
                style: theme.textTheme.bodySmall?.copyWith(color: noteColor),
              ),
              Text(
                formatCurrency(goal.targetAmount),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      footer: GoalCardFooter(
        buttons: [
          TextButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow_outlined, size: 18),
            label: const Text('Reanudar'),
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
