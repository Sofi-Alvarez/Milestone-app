import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';

class TotalSavedCard extends StatelessWidget {
  const TotalSavedCard({
    super.key,
    required this.total,
    required this.monthChangePercent,
    required this.onNewGoal,
  });

  final double total;
  final double monthChangePercent;
  final VoidCallback onNewGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = monthChangePercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(HitoRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ahorrado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: HitoSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: HitoSpacing.sm,
            runSpacing: HitoSpacing.xs,
            children: [
              Text(
                formatCurrency(total),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    ' ${isPositive ? '+' : ''}${monthChangePercent.toStringAsFixed(0)}% este mes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPositive
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNewGoal,
              child: const Text('Nueva meta'),
            ),
          ),
        ],
      ),
    );
  }
}
