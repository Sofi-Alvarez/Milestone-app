import 'package:flutter/material.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'budget_detail_screen.dart';
import 'budget_progress.dart';
import 'create_budget_screen.dart';
import 'widgets/goal_form_fields.dart';

void openBudgetHistoryScreen(
  BuildContext context, {
  required BudgetsRepository budgetsRepository,
  required TransactionsRepository transactionsRepository,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BudgetHistoryScreen(
        budgetsRepository: budgetsRepository,
        transactionsRepository: transactionsRepository,
      ),
    ),
  );
}

class BudgetHistoryScreen extends StatelessWidget {
  const BudgetHistoryScreen({
    super.key,
    required this.budgetsRepository,
    required this.transactionsRepository,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        title: const Text('Historial de presupuestos'),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Budget>>(
          stream: budgetsRepository.watchBudgets(),
          builder: (context, budgetSnapshot) {
            final budgets = budgetSnapshot.data ?? const <Budget>[];
            if (budgetSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (budgets.isEmpty) {
              return Center(
                child: Text(
                  'Todavía no creaste ningún presupuesto.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return StreamBuilder<List<MoneyTransaction>>(
              stream: transactionsRepository.watchTransactions(limit: 500),
              builder: (context, txSnapshot) {
                final transactions =
                    txSnapshot.data ?? const <MoneyTransaction>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    HitoSpacing.lg,
                    HitoSpacing.md,
                    HitoSpacing.lg,
                    HitoSpacing.xxl,
                  ),
                  children: [
                    Text(
                      budgets.length == 1
                          ? '1 presupuesto'
                          : '${budgets.length} presupuestos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: HitoSpacing.md),
                    for (final budget in budgets) ...[
                      _BudgetHistoryTile(
                        budget: budget,
                        progress: computeBudgetProgress(budget, transactions),
                        onView: () => openBudgetDetailScreen(
                          context,
                          budgetsRepository: budgetsRepository,
                          transactionsRepository: transactionsRepository,
                          budget: budget,
                        ),
                        onDuplicate: () => openCreateBudgetScreen(
                          context,
                          repository: budgetsRepository,
                          duplicateFrom: budget,
                        ),
                      ),
                      const SizedBox(height: HitoSpacing.sm),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BudgetHistoryTile extends StatelessWidget {
  const _BudgetHistoryTile({
    required this.budget,
    required this.progress,
    required this.onView,
    required this.onDuplicate,
  });

  final Budget budget;
  final BudgetProgress progress;
  final VoidCallback onView;
  final VoidCallback onDuplicate;

  String get _relativeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    );
    if (start == today) return 'hoy';
    return formatGoalDate(budget.startDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = budget.status == BudgetStatus.cancelled
        ? 'Cancelado'
        : budget.isPastEnd
        ? 'Cerrado'
        : budget.status.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _relativeLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Gasto',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatCurrency(progress.spentTotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${formatGoalDate(budget.startDate)} — ${formatGoalDate(budget.endDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Estado: $statusLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Ver'),
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDuplicate,
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Duplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
