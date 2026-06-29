import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'edit_goal_screen.dart';
import 'widgets/add_savings_sheet.dart';
import 'widgets/goal_form_fields.dart';
import 'widgets/goal_progress_donut.dart';

void openGoalDetail(
  BuildContext context, {
  required GoalsRepository repository,
  required Goal goal,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => GoalDetailScreen(repository: repository, goal: goal),
    ),
  );
}

/// Vista detalle para una meta activa o pausada — mismo layout, solo
/// cambia la etiqueta/color del badge de estado.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({
    super.key,
    required this.repository,
    required this.goal,
  });

  final GoalsRepository repository;
  final Goal goal;

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (goal.lifecycle == GoalLifecycle.paused) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? HitoColors.warningDark : HitoColors.warningLight;
    }
    switch (goal.pace) {
      case GoalPace.onTime:
        return colorScheme.onSurfaceVariant;
      case GoalPace.late:
        return colorScheme.error;
      case GoalPace.ahead:
        return colorScheme.tertiary;
    }
  }

  String get _statusLabel =>
      goal.lifecycle == GoalLifecycle.paused ? 'Pausada' : goal.paceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Vista detalle'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => openEditGoalScreen(
              context,
              repository: repository,
              goal: goal,
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            HitoSpacing.lg,
            HitoSpacing.md,
            HitoSpacing.lg,
            HitoSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(goal.title, style: theme.textTheme.headlineMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HitoSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(HitoRadius.lg),
                    ),
                    child: Text(
                      _statusLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.xs),
              Text(
                goal.targetDate == null
                    ? 'Sin fecha objetivo'
                    : 'Fecha objetivo: ${formatGoalDate(goal.targetDate!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: HitoSpacing.lg),
              Center(child: GoalProgressDonut(progress: goal.progress)),
              const SizedBox(height: HitoSpacing.md),
              Center(
                child: Text(
                  '${formatCurrency(goal.savedAmount)}/${formatCurrency(goal.targetAmount)} ARS',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: HitoSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HitoSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorro sugerido',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(goal.suggestedDaily),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          ' / día',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HitoSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Último ingreso',
                      value: goal.lastEntryAmount == null
                          ? 'Sin movimientos'
                          : formatCurrency(goal.lastEntryAmount!),
                    ),
                  ),
                  const SizedBox(width: HitoSpacing.sm),
                  Expanded(
                    child: _InfoTile(
                      label: 'Tiempo estimado',
                      value: goal.targetDate == null
                          ? 'Sin fecha'
                          : '${goal.estimatedWeeksLeft} semanas',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HitoSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip de ahorro',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Redondea tus gastos y guarda la diferencia.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          HitoSpacing.lg,
          HitoSpacing.sm,
          HitoSpacing.lg,
          HitoSpacing.md,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => addSavingsAndNotify(
              context,
              repository: repository,
              goalId: goal.id,
            ),
            child: const Text('Añadir ahorro'),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
