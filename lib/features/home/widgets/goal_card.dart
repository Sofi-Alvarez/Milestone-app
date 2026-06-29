import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/home_models.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onPrimaryAction,
  });

  final SavingsGoal goal;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalAmountLabel = goal.isActive
        ? 'Meta ${formatCurrency(goal.target!)}'
        : 'Retomá tu hábito';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(HitoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: HitoColors.neutral900Light.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HitoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: HitoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(goal.current),
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(goalAmountLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Text(
                '%${(goal.progress * 100).round()}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimaryAction,
              child: Text(goal.isActive ? 'Ver detalles' : 'Definir meta'),
            ),
          ),
        ],
      ),
    );
  }
}
