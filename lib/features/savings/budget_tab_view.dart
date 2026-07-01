import 'package:flutter/material.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'budget_detail_screen.dart';
import 'budget_history_screen.dart';
import 'budget_progress.dart';
import 'create_budget_screen.dart';

/// Contenido de la pestaña "Presupuesto" en Ahorro — mismos patrones
/// visuales que Metas (hero card, cards con sombra, progreso) e
/// Historial (chips de estado, distribución por categoría).
class BudgetTabView extends StatelessWidget {
  const BudgetTabView({
    super.key,
    required this.budgetsRepository,
    required this.transactionsRepository,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Budget?>(
      stream: budgetsRepository.watchCurrentBudget(),
      builder: (context, budgetSnapshot) {
        // OJO: no usar `hasData` acá — el stream emite `null` de forma
        // legítima cuando no hay presupuesto vigente, y `hasData` lo
        // trata igual que "todavía no llegó nada" (queda cargando para
        // siempre). `connectionState` es la señal correcta de espera.
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(HitoSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final budget = budgetSnapshot.data;
        if (budget == null) {
          return _EmptyBudgetState(
            budgetsRepository: budgetsRepository,
            transactionsRepository: transactionsRepository,
          );
        }
        return StreamBuilder<List<MoneyTransaction>>(
          stream: transactionsRepository.watchTransactions(limit: 500),
          builder: (context, txSnapshot) {
            final transactions = txSnapshot.data ?? const <MoneyTransaction>[];
            final progress = computeBudgetProgress(budget, transactions);
            return _ActiveBudgetCard(
              budget: budget,
              progress: progress,
              budgetsRepository: budgetsRepository,
              transactionsRepository: transactionsRepository,
            );
          },
        );
      },
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({required this.budgetsRepository, required this.transactionsRepository});

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            'Sin presupuesto activo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: HitoSpacing.xs),
          Text(
            'Definí un límite de gasto para el período y te avisamos '
            'si te estás por pasar.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: HitoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => openCreateBudgetScreen(context, repository: budgetsRepository),
              child: const Text('Crear presupuesto'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => openBudgetHistoryScreen(
                context,
                budgetsRepository: budgetsRepository,
                transactionsRepository: transactionsRepository,
              ),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimaryContainer),
              child: const Text('Ver historial'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBudgetCard extends StatelessWidget {
  const _ActiveBudgetCard({
    required this.budget,
    required this.progress,
    required this.budgetsRepository,
    required this.transactionsRepository,
  });

  final Budget budget;
  final BudgetProgress progress;
  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget.limitAmount <= 0
        ? 0.0
        : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);
    final health = budgetHealthFor(progress.spentTotal, budget.limitAmount);
    final statusColor = switch (health) {
      BudgetHealthStatus.exceeded => theme.colorScheme.error,
      BudgetHealthStatus.nearLimit => HitoColors.warningLight,
      BudgetHealthStatus.onTrack => theme.colorScheme.onSurfaceVariant,
    };
    final statusLabel = budget.status == BudgetStatus.paused
        ? 'Pausado'
        : switch (health) {
            BudgetHealthStatus.exceeded => 'Excedido',
            BudgetHealthStatus.nearLimit => 'Cerca del límite',
            BudgetHealthStatus.onTrack =>
              budget.isPastEnd ? 'Vencido' : '${budget.daysLeft} días restantes',
          };

    return InkWell(
      borderRadius: BorderRadius.circular(HitoRadius.md),
      onTap: () => openBudgetDetailScreen(
        context,
        budgetsRepository: budgetsRepository,
        transactionsRepository: transactionsRepository,
        budget: budget,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
          boxShadow: cardShadow(),
        ),
        padding: const EdgeInsets.all(HitoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.pie_chart_outline,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(progress.spentTotal),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'de ${formatCurrency(budget.limitAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: pageColor(theme),
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Text('%${(ratio * 100).round()}', style: theme.textTheme.labelLarge),
              ],
            ),
            Divider(
              height: HitoSpacing.lg,
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => openBudgetDetailScreen(
                    context,
                    budgetsRepository: budgetsRepository,
                    transactionsRepository: transactionsRepository,
                    budget: budget,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver detalle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
