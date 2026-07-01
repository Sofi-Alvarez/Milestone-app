import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ring.dart';
import '../home/models/home_models.dart';
import 'edit_goal_screen.dart';
import 'widgets/add_savings_sheet.dart';
import 'widgets/goal_form_fields.dart';

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
/// cambia la etiqueta/color del badge de estado. Escucha la meta en vivo
/// (vía [GoalsRepository.watchGoal]) para reflejar pausa/reinicio hechos
/// desde Editar meta sin necesitar volver atrás; si la meta se elimina,
/// vuelve sola a la pantalla de Ahorro.
class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.repository,
    required this.goal,
  });

  final GoalsRepository repository;
  final Goal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  bool _poppedForDeletion = false;

  Color _statusColor(BuildContext context, Goal goal) {
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

  String _statusLabel(Goal goal) =>
      goal.lifecycle == GoalLifecycle.paused ? 'Pausada' : goal.paceLabel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Goal?>(
      stream: widget.repository.watchGoal(widget.goal.id),
      initialData: widget.goal,
      builder: (context, snapshot) {
        final goal = snapshot.data;
        if (goal == null) {
          if (!_poppedForDeletion) {
            _poppedForDeletion = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }
          return const Scaffold(body: SizedBox.shrink());
        }
        return _GoalDetailBody(
          repository: widget.repository,
          goal: goal,
          statusColor: _statusColor(context, goal),
          statusLabel: _statusLabel(goal),
        );
      },
    );
  }
}

class _GoalDetailBody extends StatelessWidget {
  const _GoalDetailBody({
    required this.repository,
    required this.goal,
    required this.statusColor,
    required this.statusLabel,
  });

  final GoalsRepository repository;
  final Goal goal;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        title: const Text('Vista detalle'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Editar meta',
            onPressed: () =>
                openEditGoalScreen(context, repository: repository, goal: goal),
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
                    child: Text(
                      goal.title,
                      style: theme.textTheme.headlineMedium,
                    ),
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
                      statusLabel,
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
              Center(
                child: ProgressRing(
                  progress: goal.progress,
                  center: Text(
                    '${(goal.progress * 100).round()}%',
                    style: theme.textTheme.displayMedium,
                  ),
                ),
              ),
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
                      value: goal.estimatedTimeLeftLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HitoSpacing.md),
                decoration: BoxDecoration(
                  color: cardColor(theme),
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                  boxShadow: cardShadow(),
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
              goalTitle: goal.title,
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
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
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
