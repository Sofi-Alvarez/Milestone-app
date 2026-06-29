import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import 'achieved_goal_detail_screen.dart';
import 'goal_detail_screen.dart';
import 'widgets/achieved_goal_card.dart';
import 'widgets/add_savings_sheet.dart';
import 'widgets/goal_summary_card.dart';
import 'widgets/paused_goal_card.dart';

enum _GoalsTab { active, paused, achieved }

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key, required this.goalsRepository});

  final GoalsRepository goalsRepository;

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  _GoalsTab _tab = _GoalsTab.active;

  (String, String) _header(int activeCount, int pausedCount, int achievedCount) {
    switch (_tab) {
      case _GoalsTab.active:
        return ('¡Metas en progreso!', 'Estás trabajando en $activeCount metas. ¡Sigue así!');
      case _GoalsTab.paused:
        return ('Metas en pausa', 'Hay $pausedCount metas aguardando tu regreso...');
      case _GoalsTab.achieved:
        return (
          '¡Metas logradas!',
          'Has completado $achievedCount metas. ¡Sigue así!',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Metas'), centerTitle: false),
      body: StreamBuilder<List<Goal>>(
        stream: widget.goalsRepository.watchGoals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data!;
          final active = goals.where((g) => g.lifecycle == GoalLifecycle.active).toList();
          final paused = goals.where((g) => g.lifecycle == GoalLifecycle.paused).toList();
          final achieved =
              goals.where((g) => g.lifecycle == GoalLifecycle.achieved).toList();
          final (title, subtitle) = _header(active.length, paused.length, achieved.length);

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                HitoSpacing.lg,
                HitoSpacing.md,
                HitoSpacing.lg,
                HitoSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_GoalsTab>(
                    segments: const [
                      ButtonSegment(value: _GoalsTab.active, label: Text('Activas')),
                      ButtonSegment(value: _GoalsTab.paused, label: Text('Pausadas')),
                      ButtonSegment(value: _GoalsTab.achieved, label: Text('Logradas')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                  ),
                  const SizedBox(height: HitoSpacing.lg),
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: HitoSpacing.lg),
                  ..._buildList(active, paused, achieved),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildList(
    List<Goal> active,
    List<Goal> paused,
    List<Goal> achieved,
  ) {
    switch (_tab) {
      case _GoalsTab.active:
        return [
          for (final goal in active) ...[
            GoalSummaryCard(
              goal: goal,
              onAddSavings: () => addSavingsAndNotify(
                context,
                repository: widget.goalsRepository,
                goalId: goal.id,
              ),
              onViewDetail: () => openGoalDetail(
                context,
                repository: widget.goalsRepository,
                goal: goal,
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
        ];
      case _GoalsTab.paused:
        return [
          for (final goal in paused) ...[
            PausedGoalCard(
              goal: goal,
              onResume: () => widget.goalsRepository.resumeGoal(goal.id),
              onViewDetail: () => openGoalDetail(
                context,
                repository: widget.goalsRepository,
                goal: goal,
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
        ];
      case _GoalsTab.achieved:
        return [
          for (final goal in achieved) ...[
            AchievedGoalCard(
              goal: goal,
              onViewDetail: () => openAchievedGoalDetail(
                context,
                repository: widget.goalsRepository,
                goal: goal,
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
        ];
    }
  }
}
