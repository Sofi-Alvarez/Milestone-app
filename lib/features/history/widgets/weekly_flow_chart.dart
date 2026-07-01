import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';

class FlowBucket {
  const FlowBucket({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}

/// "Flujo semanal" — barras Ingresos/Gastos por día. Verde para
/// ingresos y rojo para gastos, igual convención que el resto de la
/// app (ver _TransactionRow en Home).
class WeeklyFlowChart extends StatelessWidget {
  const WeeklyFlowChart({super.key, required this.buckets});

  final List<FlowBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeColor = isDark
        ? HitoColors.successDark
        : HitoColors.successLight;
    final expenseColor = theme.colorScheme.error;

    final totalIncome = buckets.fold<double>(0, (sum, b) => sum + b.income);
    final totalExpense = buckets.fold<double>(0, (sum, b) => sum + b.expense);
    final maxValue = buckets.fold<double>(
      1,
      (max, b) => [max, b.income, b.expense].reduce((a, c) => a > c ? a : c),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.hero),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flujo semanal',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Últimos 7 días',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LegendRow(
                    color: incomeColor,
                    label: 'Ingresos',
                    value: totalIncome,
                  ),
                  const SizedBox(height: 4),
                  _LegendRow(
                    color: expenseColor,
                    label: 'Gastos',
                    value: totalExpense,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.lg),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final bucket in buckets)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 77,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Bar(
                              height: 77 * (bucket.income / maxValue),
                              color: incomeColor,
                            ),
                            const SizedBox(width: 2),
                            _Bar(
                              height: 77 * (bucket.expense / maxValue),
                              color: expenseColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: HitoSpacing.sm),
                      Text(
                        bucket.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height.clamp(2, 77),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          formatCurrency(value),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
