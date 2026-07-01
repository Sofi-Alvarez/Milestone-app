import 'package:flutter/material.dart';

import '../../../data/goal.dart';
import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';
import 'goal_card_shell.dart';

class AchievedGoalCard extends StatelessWidget {
  const AchievedGoalCard({
    super.key,
    required this.goal,
    required this.onViewDetail,
  });

  final Goal goal;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final achievedColor =
        isDark ? HitoColors.successDark : HitoColors.successLight;
    final noteColor = theme.colorScheme.onSurfaceVariant;
    final achievedDate = goal.achievedAt;

    return GoalCardShell(
      title: goal.title,
      statusLabel: 'Lograda',
      statusLabelColor: achievedColor,
      trailingValue: formatCurrency(goal.targetAmount),
      trailingLabel: 'Objetivo',
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoalProgressRow(progress: 1),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                achievedDate == null ? '—' : formatGoalShortDate(achievedDate),
                style: theme.textTheme.bodySmall?.copyWith(color: noteColor),
              ),
              Text(
                'En ${_durationLabel(goal)}',
                style: theme.textTheme.bodySmall?.copyWith(color: noteColor),
              ),
            ],
          ),
        ],
      ),
      footer: GoalCardFooter(
        buttons: [
          TextButton.icon(
            onPressed: onViewDetail,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Ver detalle'),
          ),
        ],
      ),
    );
  }

  String _durationLabel(Goal goal) {
    final end = goal.achievedAt ?? DateTime.now();
    return formatDuration(end.difference(goal.createdAt).inDays);
  }
}

String formatGoalShortDate(DateTime date) {
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
