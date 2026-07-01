import 'package:flutter/material.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stat_value.dart';
import '../home/models/home_models.dart';
import 'budget_detail_screen.dart';
import 'budget_history_screen.dart';
import 'budget_progress.dart';
import 'create_budget_screen.dart';
import 'widgets/budget_status_pill.dart';

/// Contenido de la pestaña "Presupuesto" en Ahorro — mismos patrones
/// visuales que Metas (hero card, cards con sombra, progreso) e
/// Historial (chips de estado, distribución por categoría).
class BudgetTabView extends StatelessWidget {
  const BudgetTabView({
    super.key,
    required this.budgetsRepository,
    required this.transactionsRepository,
    required this.explorationBudget,
    required this.onLoadExample,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;

  /// Si viene seteado, la pestaña muestra este presupuesto de muestra
  /// en vez de consultar Firestore — nunca se persiste, es puramente
  /// local ("Cargar un ejemplo para explorar").
  final Budget? explorationBudget;
  final VoidCallback onLoadExample;

  @override
  Widget build(BuildContext context) {
    if (explorationBudget != null) {
      return _ActiveBudgetView(
        budget: explorationBudget!,
        progress: exampleBudgetProgress,
        budgetsRepository: budgetsRepository,
        transactionsRepository: transactionsRepository,
        isExample: true,
      );
    }
    return StreamBuilder<Budget?>(
      stream: budgetsRepository.watchCurrentBudget(),
      builder: (context, budgetSnapshot) {
        // OJO: no usar `hasData` acá — el stream emite `null` de forma
        // legítima cuando no hay presupuesto vigente, y `hasData` lo
        // trata igual que "todavía no llegó nada" (queda cargando para
        // siempre). `connectionState` es la señal correcta de espera.
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(HitoSpacing.md),
            child: SkeletonListCardGroup(count: 3),
          );
        }
        final budget = budgetSnapshot.data;
        if (budget == null) {
          return _EmptyBudgetState(
            budgetsRepository: budgetsRepository,
            transactionsRepository: transactionsRepository,
            onLoadExample: onLoadExample,
          );
        }
        return StreamBuilder<List<MoneyTransaction>>(
          stream: transactionsRepository.watchTransactions(limit: 500),
          builder: (context, txSnapshot) {
            final transactions = txSnapshot.data ?? const <MoneyTransaction>[];
            final progress = computeBudgetProgress(budget, transactions);
            return _ActiveBudgetView(
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

/// Presupuesto de muestra usado por "Cargar un ejemplo para explorar"
/// — construido en el momento (la fecha límite siempre queda a 30 días
/// desde hoy) y nunca escrito en Firestore.
Budget buildExampleBudget() {
  final now = DateTime.now();
  return Budget(
    id: '',
    name: 'Presupuesto de octubre',
    type: BudgetType.byCategory,
    limitAmount: 180000,
    startDate: now,
    endDate: now.add(const Duration(days: 30)),
    note: '',
    notifyExceeded: true,
    notifyNearLimit: true,
    status: BudgetStatus.active,
    categories: const [
      BudgetCategoryAllocation(
        categoryId: 'comestibles',
        categoryLabel: 'Comida',
        limitAmount: 80000,
      ),
      BudgetCategoryAllocation(
        categoryId: 'transporte',
        categoryLabel: 'Transporte',
        limitAmount: 30000,
      ),
      BudgetCategoryAllocation(
        categoryId: 'entretenimiento',
        categoryLabel: 'Ocio',
        limitAmount: 25000,
      ),
      BudgetCategoryAllocation(
        categoryId: 'hogar',
        categoryLabel: 'Hogar',
        limitAmount: 45000,
      ),
    ],
    createdAt: now,
  );
}

final exampleBudgetProgress = BudgetProgress(
  spentTotal: 127500,
  spentByCategory: const {
    'comestibles': 72000,
    'transporte': 12500,
    'entretenimiento': 28000,
    'hogar': 15000,
  },
);

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({
    required this.budgetsRepository,
    required this.transactionsRepository,
    required this.onLoadExample,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;
  final VoidCallback onLoadExample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HitoSpacing.lg),
          decoration: BoxDecoration(
            color: cardColor(theme),
            borderRadius: BorderRadius.circular(HitoRadius.lg),
            boxShadow: cardShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: HitoSpacing.md),
              Text(
                'Empieza tu presupuesto',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: HitoSpacing.xs),
              Text(
                'Definí un límite para este período y elegí si desea monitorearlo '
                'en total o por categorías. Sin presión, siempre editable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: HitoSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => openCreateBudgetScreen(
                    context,
                    repository: budgetsRepository,
                  ),
                  child: const Text('Crear presupuesto'),
                ),
              ),
              const SizedBox(height: HitoSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onLoadExample,
                  child: const Text('Cargar un ejemplo'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(HitoRadius.md),
          onTap: () => openBudgetHistoryScreen(
            context,
            budgetsRepository: budgetsRepository,
            transactionsRepository: transactionsRepository,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.md),
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
              boxShadow: cardShadow(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ver historial de presupuestos',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveBudgetView extends StatelessWidget {
  const _ActiveBudgetView({
    required this.budget,
    required this.progress,
    required this.budgetsRepository,
    required this.transactionsRepository,
    this.isExample = false,
  });

  final Budget budget;
  final BudgetProgress progress;
  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;
  final bool isExample;

  void _openDetail(BuildContext context) => openBudgetDetailScreen(
    context,
    budgetsRepository: budgetsRepository,
    transactionsRepository: transactionsRepository,
    budget: budget,
    exampleProgress: isExample ? progress : null,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget.limitAmount <= 0
        ? 0.0
        : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);
    final remaining = budget.limitAmount - progress.spentTotal;
    final health = budgetHealthFor(progress.spentTotal, budget.limitAmount);

    final urgent = <BudgetCategoryAllocation>[];
    final onTrack = <BudgetCategoryAllocation>[];
    for (final c in budget.categories) {
      final h = budgetHealthFor(progress.spentFor(c.categoryId), c.limitAmount);
      (h == BudgetHealthStatus.onTrack ? onTrack : urgent).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(HitoRadius.lg),
          onTap: () => _openDetail(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.lg),
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.lg),
              boxShadow: cardShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto activo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(budget.name, style: theme.textTheme.headlineMedium),
                const SizedBox(height: HitoSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatCurrency(progress.spentTotal),
                      style: theme.textTheme.displayMedium,
                    ),
                    Text(
                      ' / ${formatCurrency(budget.limitAmount)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HitoSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: recessedColor(theme),
                    color: progressColorFor(context, health),
                  ),
                ),
                const SizedBox(height: HitoSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatValue(
                        label: remaining >= 0 ? 'Disponible' : 'Excedido por',
                        value: formatCurrency(remaining.abs()),
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    Expanded(
                      child: StatValue(
                        label: 'Restan',
                        value: budget.isPastEnd
                            ? 'Vencido'
                            : '${budget.daysLeft} días',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: HitoSpacing.md),
        _HealthBannerCompact(
          health: health,
          hasSpending: progress.spentTotal > 0,
        ),
        if (budget.type == BudgetType.byCategory &&
            budget.categories.isNotEmpty) ...[
          if (urgent.isNotEmpty) ...[
            const SizedBox(height: HitoSpacing.lg),
            Text('Atención inmediata', style: theme.textTheme.headlineMedium),
            const SizedBox(height: HitoSpacing.sm),
            for (final c in urgent) ...[
              _CategoryMiniRow(
                allocation: c,
                spent: progress.spentFor(c.categoryId),
              ),
              const SizedBox(height: HitoSpacing.sm),
            ],
          ],
          if (onTrack.isNotEmpty) ...[
            const SizedBox(height: HitoSpacing.sm),
            Text('Bajo control', style: theme.textTheme.headlineMedium),
            const SizedBox(height: HitoSpacing.sm),
            for (final c in onTrack) ...[
              _CategoryMiniRow(
                allocation: c,
                spent: progress.spentFor(c.categoryId),
              ),
              const SizedBox(height: HitoSpacing.sm),
            ],
          ],
        ],
        const SizedBox(height: HitoSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(HitoRadius.md),
          onTap: () => _openDetail(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.md),
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
              boxShadow: cardShadow(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ver detalle del presupuesto',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthBannerCompact extends StatelessWidget {
  const _HealthBannerCompact({required this.health, required this.hasSpending});

  final BudgetHealthStatus health;
  final bool hasSpending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!hasSpending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HitoSpacing.md),
        decoration: BoxDecoration(
          color: recessedColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Text(
                'Aún no registraste gastos. Cuando anotes uno, lo verás reflejado acá.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final (bg, fg, icon, message) = switch (health) {
      BudgetHealthStatus.exceeded => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.error_outline,
        'Superaste tu límite. Podés ajustar el presupuesto o revisar tus gastos, sin drama.',
      ),
      BudgetHealthStatus.nearLimit => (
        HitoColors.warningContainerLight,
        HitoColors.warningLight,
        Icons.info_outline,
        'Estás cerca del límite — respirá y revisá tus gastos.',
      ),
      BudgetHealthStatus.onTrack => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.check_circle_outline,
        'Vas en camino. Tenés margen disponible, seguí con tu ritmo.',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMiniRow extends StatelessWidget {
  const _CategoryMiniRow({required this.allocation, required this.spent});

  final BudgetCategoryAllocation allocation;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final health = budgetHealthFor(spent, allocation.limitAmount);
    final ratio = allocation.limitAmount <= 0
        ? 0.0
        : (spent / allocation.limitAmount).clamp(0.0, 1.0);
    final pillLabel = spent == 0
        ? 'Sin movimientos'
        : switch (health) {
            BudgetHealthStatus.exceeded => 'Excedido',
            BudgetHealthStatus.nearLimit => 'Al límite',
            BudgetHealthStatus.onTrack => 'En curso',
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: HitoSpacing.md,
        vertical: HitoSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  findCategory(allocation.categoryId)?.icon ??
                      Icons.category_outlined,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allocation.categoryLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${formatCurrencyCompact(spent)} de ${formatCurrencyCompact(allocation.limitAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              BudgetStatusPill(label: pillLabel, health: health),
            ],
          ),
          const SizedBox(height: HitoSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 44 + HitoSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(HitoRadius.full),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: recessedColor(theme),
                      color: progressColorFor(context, health),
                    ),
                  ),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Text(
                  '${(ratio * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
