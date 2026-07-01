import 'package:flutter/material.dart';

import '../../data/budgets_repository.dart';
import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import 'budget_tab_view.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';
import 'goals_list_screen.dart';
import 'widgets/add_savings_sheet.dart';
import 'widgets/analysis_card.dart';
import 'widgets/goal_form_fields.dart';
import 'widgets/goal_summary_card.dart';
import 'widgets/total_saved_card.dart';

enum _SavingsTab { metas, presupuesto }

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.budgetsRepository,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final BudgetsRepository budgetsRepository;

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  _SavingsTab _tab = _SavingsTab.metas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        title: const Text('Ahorro'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Goal>>(
        stream: widget.goalsRepository.watchGoals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data!;
          final active = goals.where((g) => g.lifecycle == GoalLifecycle.active).toList();
          final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.savedAmount);

          Goal? nextDue;
          for (final g in active) {
            if (g.targetDate == null) continue;
            if (nextDue == null || g.targetDate!.isBefore(nextDue.targetDate!)) {
              nextDue = g;
            }
          }

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
                  HitoToggle<_SavingsTab>(
                    options: const [
                      (_SavingsTab.metas, 'Metas'),
                      (_SavingsTab.presupuesto, 'Presupuesto'),
                    ],
                    selected: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  const SizedBox(height: HitoSpacing.lg),
                  if (_tab == _SavingsTab.presupuesto)
                    BudgetTabView(
                      budgetsRepository: widget.budgetsRepository,
                      transactionsRepository: widget.transactionsRepository,
                    )
                  else ...[
                  TotalSavedCard(
                    total: totalSaved,
                    monthChangePercent: 0,
                    onNewGoal: () => openCreateGoalScreen(
                      context,
                      repository: widget.goalsRepository,
                    ),
                  ),
                  const SizedBox(height: HitoSpacing.lg),
                  Text('Análisis de progreso', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: HitoSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AnalysisCard(
                          icon: Icons.schedule,
                          label: 'Ritmo actual',
                          value: nextDue?.paceLabel ?? 'Sin datos',
                        ),
                      ),
                      const SizedBox(width: HitoSpacing.sm),
                      Expanded(
                        child: AnalysisCard(
                          icon: Icons.event_outlined,
                          label: 'Próximo hito',
                          value: nextDue == null
                              ? 'Sin datos'
                              : formatGoalDate(nextDue.targetDate!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HitoSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Proyección de metas', style: theme.textTheme.headlineMedium),
                      TextButton(
                        onPressed: goals.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GoalsListScreen(
                                      goalsRepository: widget.goalsRepository,
                                    ),
                                  ),
                                ),
                        child: const Text('Ver todo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                  if (active.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(HitoSpacing.lg),
                      decoration: BoxDecoration(
                        color: cardColor(theme),
                        borderRadius: BorderRadius.circular(HitoRadius.md),
                        boxShadow: cardShadow(),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Todavía no tenés metas activas. ¡Creá la primera!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (final goal in active) ...[
                      GoalSummaryCard(
                        goal: goal,
                        onAddSavings: () => addSavingsAndNotify(
                          context,
                          repository: widget.goalsRepository,
                          goalId: goal.id,
                          goalTitle: goal.title,
                        ),
                        onViewDetail: () => openGoalDetail(
                          context,
                          repository: widget.goalsRepository,
                          goal: goal,
                        ),
                      ),
                      const SizedBox(height: HitoSpacing.sm),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
