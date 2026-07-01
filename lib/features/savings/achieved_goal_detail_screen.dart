import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ring.dart';
import '../home/models/home_models.dart';
import 'create_goal_screen.dart';
import 'widgets/goal_form_fields.dart';

void openAchievedGoalDetail(
  BuildContext context, {
  required GoalsRepository repository,
  required Goal goal,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          AchievedGoalDetailScreen(repository: repository, goal: goal),
    ),
  );
}

/// Vista detalle para una meta lograda. No hay frame de Figma para este
/// caso específico — se extrapola del mismo patrón que activa/pausada
/// (lib/features/savings/goal_detail_screen.dart), adaptando el contenido
/// a un estado de cierre: sin "añadir ahorro" ni "tiempo estimado", con
/// un resumen de cierre y CTA para una meta nueva.
class AchievedGoalDetailScreen extends StatelessWidget {
  const AchievedGoalDetailScreen({
    super.key,
    required this.repository,
    required this.goal,
  });

  final GoalsRepository repository;
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final achievedColor = isDark
        ? HitoColors.successDark
        : HitoColors.successLight;
    final achievedDate = goal.achievedAt;
    final durationLabel = achievedDate == null
        ? '—'
        : formatDuration(achievedDate.difference(goal.createdAt).inDays);
    final onTime =
        goal.targetDate != null &&
        achievedDate != null &&
        !achievedDate.isAfter(goal.targetDate!);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(title: const Text('Vista detalle'), centerTitle: false),
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
                      color: achievedColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(HitoRadius.lg),
                    ),
                    child: Text(
                      'Lograda',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: achievedColor,
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
                  progress: 1,
                  center: Text('100%', style: theme.textTheme.displayMedium),
                ),
              ),
              const SizedBox(height: HitoSpacing.md),
              Center(
                child: Text(
                  '${formatCurrency(goal.targetAmount)}/${formatCurrency(goal.targetAmount)} ARS',
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
                      '¡Meta cumplida!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Lograste ahorrar ${formatCurrency(goal.targetAmount)} en total. '
                      'Es un buen momento para definir tu próximo hito.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HitoSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Fecha alcanzada',
                      value: achievedDate == null
                          ? '—'
                          : formatGoalDate(achievedDate),
                      note: onTime ? 'Lograda en tiempo' : null,
                      noteColor: achievedColor,
                    ),
                  ),
                  const SizedBox(width: HitoSpacing.sm),
                  Expanded(
                    child: _InfoTile(
                      label: 'Lo logró en',
                      value: durationLabel,
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
                            'Redirigí ese mismo monto diario hacia tu '
                            'próxima meta para no perder el ritmo.',
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
            onPressed: () =>
                openCreateGoalScreen(context, repository: repository),
            child: const Text('Crear nueva meta'),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
  });

  final String label;
  final String value;
  final String? note;
  final Color? noteColor;

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
          Text(
            note ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: note == null
                  ? Colors.transparent
                  : (noteColor ?? theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
