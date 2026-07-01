import 'package:flutter/material.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'budget_detail_screen.dart';
import 'budget_progress.dart';
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
      appBar: AppBar(title: const Text('Historial de presupuestos'), centerTitle: false),
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
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }
            return StreamBuilder<List<MoneyTransaction>>(
              stream: transactionsRepository.watchTransactions(limit: 500),
              builder: (context, txSnapshot) {
                final transactions = txSnapshot.data ?? const <MoneyTransaction>[];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    HitoSpacing.lg,
                    HitoSpacing.md,
                    HitoSpacing.lg,
                    HitoSpacing.xxl,
                  ),
                  itemCount: budgets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: HitoSpacing.sm),
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final progress = computeBudgetProgress(budget, transactions);
                    return _BudgetHistoryTile(
                      budget: budget,
                      progress: progress,
                      onTap: () => openBudgetDetailScreen(
                        context,
                        budgetsRepository: budgetsRepository,
                        transactionsRepository: transactionsRepository,
                        budget: budget,
                      ),
                    );
                  },
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
  const _BudgetHistoryTile({required this.budget, required this.progress, required this.onTap});

  final Budget budget;
  final BudgetProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = budget.status == BudgetStatus.cancelled
        ? 'Cancelado'
        : budget.isPastEnd
            ? 'Cerrado'
            : budget.status.label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: Container(
        padding: const EdgeInsets.all(HitoSpacing.md),
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
          boxShadow: cardShadow(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$statusLabel · ${formatGoalDate(budget.startDate)} - ${formatGoalDate(budget.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${formatCurrency(progress.spentTotal)} / ${formatCurrency(budget.limitAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
