import 'package:flutter/material.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../home/models/home_models.dart';
import 'budget_history_screen.dart';
import 'budget_progress.dart';
import 'create_budget_screen.dart';

void openBudgetDetailScreen(
  BuildContext context, {
  required BudgetsRepository budgetsRepository,
  required TransactionsRepository transactionsRepository,
  required Budget budget,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BudgetDetailScreen(
        budgetsRepository: budgetsRepository,
        transactionsRepository: transactionsRepository,
        budget: budget,
      ),
    ),
  );
}

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({
    super.key,
    required this.budgetsRepository,
    required this.transactionsRepository,
    required this.budget,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;
  final Budget budget;

  Future<void> _pause(BuildContext context) async {
    final resume = budget.status == BudgetStatus.paused;
    await budgetsRepository.setStatus(
      budget.id,
      resume ? BudgetStatus.active : BudgetStatus.paused,
    );
    if (context.mounted) {
      showAppSnackBar(context, resume ? 'Presupuesto reactivado' : 'Presupuesto pausado');
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: '¿Cancelar presupuesto?',
      body: 'Se cancelará el presupuesto, pero conservás su historial.',
      confirmLabel: 'Cancelar presupuesto',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await budgetsRepository.setStatus(budget.id, BudgetStatus.cancelled);
    if (context.mounted) {
      showAppSnackBar(context, 'Presupuesto cancelado');
      Navigator.of(context).pop();
    }
  }

  Budget _withCategories(List<BudgetCategoryAllocation> categories) => Budget(
        id: budget.id,
        name: budget.name,
        type: budget.type,
        limitAmount: budget.limitAmount,
        startDate: budget.startDate,
        endDate: budget.endDate,
        note: budget.note,
        notifyExceeded: budget.notifyExceeded,
        notifyNearLimit: budget.notifyNearLimit,
        status: budget.status,
        categories: categories,
        createdAt: budget.createdAt,
      );

  /// Mueve fondos del límite de una categoría con sobrante hacia una
  /// categoría excedida o cerca del límite — ajusta los límites
  /// asignados, no el gasto real (que sigue viniendo de las
  /// transacciones tal cual pasaron).
  Future<void> _reassignFunds(
    BuildContext context,
    BudgetProgress progress,
    BudgetCategoryAllocation target,
  ) async {
    final candidates = budget.categories.where((c) {
      if (c.categoryId == target.categoryId) return false;
      return c.limitAmount - progress.spentFor(c.categoryId) > 0;
    }).toList();
    if (candidates.isEmpty) {
      showAppSnackBar(context, 'No hay categorías con sobrante para reasignar');
      return;
    }
    final result = await showModalBottomSheet<_ReassignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReassignFundsSheet(target: target, candidates: candidates, progress: progress),
    );
    if (result == null || !context.mounted) return;

    final updated = budget.categories.map((c) {
      if (c.categoryId == result.fromCategoryId) {
        return BudgetCategoryAllocation(
          categoryId: c.categoryId,
          categoryLabel: c.categoryLabel,
          limitAmount: c.limitAmount - result.amount,
        );
      }
      if (c.categoryId == target.categoryId) {
        return BudgetCategoryAllocation(
          categoryId: c.categoryId,
          categoryLabel: c.categoryLabel,
          limitAmount: c.limitAmount + result.amount,
        );
      }
      return c;
    }).toList();

    try {
      await budgetsRepository.updateBudget(budget.id, _withCategories(updated));
      if (context.mounted) showAppSnackBar(context, 'Fondos reasignados');
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'No pudimos reasignar los fondos: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        title: Text(budget.name),
        centerTitle: false,
        actions: [
          if (!budget.isPastEnd)
            IconButton(
              tooltip: 'Editar presupuesto',
              onPressed: () => openCreateBudgetScreen(
                context,
                repository: budgetsRepository,
                existingBudget: budget,
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<MoneyTransaction>>(
          stream: transactionsRepository.watchTransactions(limit: 500),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? const <MoneyTransaction>[];
            final progress = computeBudgetProgress(budget, transactions);
            final health = budgetHealthFor(progress.spentTotal, budget.limitAmount);

            // Pasada la fecha límite, el presupuesto "se cierra" solo —
            // no hay job de servidor que lo marque, así que el cierre se
            // muestra apenas alguien vuelve a abrir este presupuesto
            // vencido, con el resumen final en vez de los controles de
            // un presupuesto en curso.
            if (budget.isPastEnd) {
              return _ClosedBudgetSummary(
                budget: budget,
                progress: progress,
                budgetsRepository: budgetsRepository,
                transactionsRepository: transactionsRepository,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                HitoSpacing.lg,
                HitoSpacing.md,
                HitoSpacing.lg,
                HitoSpacing.xxl,
              ),
              children: [
                _BudgetHeroCard(budget: budget, progress: progress, health: health),
                const SizedBox(height: HitoSpacing.md),
                if (health != BudgetHealthStatus.onTrack)
                  Padding(
                    padding: const EdgeInsets.only(bottom: HitoSpacing.md),
                    child: _HealthBanner(health: health),
                  ),
                if (budget.type == BudgetType.byCategory && budget.categories.isNotEmpty) ...[
                  _CategoryGroups(
                    budget: budget,
                    progress: progress,
                    onReassign: (target) => _reassignFunds(context, progress, target),
                  ),
                  const SizedBox(height: HitoSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pause(context),
                        child: Text(
                          budget.status == BudgetStatus.paused ? 'Reanudar' : 'Pausar',
                        ),
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                        ),
                        onPressed: () => _cancel(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HitoSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => openCreateBudgetScreen(
                      context,
                      repository: budgetsRepository,
                      duplicateFrom: budget,
                    ),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Duplicar como nuevo presupuesto'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BudgetHeroCard extends StatelessWidget {
  const _BudgetHeroCard({required this.budget, required this.progress, required this.health});

  final Budget budget;
  final BudgetProgress progress;
  final BudgetHealthStatus health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget.limitAmount <= 0
        ? 0.0
        : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);
    final remaining = budget.limitAmount - progress.spentTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: heroShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GASTADO DE ${formatCurrency(budget.limitAmount)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
              _StatusChip(status: budget.status, health: health),
            ],
          ),
          const SizedBox(height: HitoSpacing.xs),
          Text(
            formatCurrency(progress.spentTotal),
            style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: HitoSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(HitoRadius.sm),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              color: health == BudgetHealthStatus.exceeded
                  ? theme.colorScheme.error
                  : theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: HitoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: remaining >= 0 ? 'Disponible' : 'Excedido por',
                  value: formatCurrency(remaining.abs()),
                ),
              ),
              const SizedBox(width: HitoSpacing.md),
              Expanded(
                child: _HeroStat(
                  label: 'Días restantes',
                  value: budget.isPastEnd ? 'Vencido' : '${budget.daysLeft}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.health});

  final BudgetStatus status;
  final BudgetHealthStatus health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = status == BudgetStatus.paused
        ? 'Pausado'
        : switch (health) {
            BudgetHealthStatus.exceeded => 'Excedido',
            BudgetHealthStatus.nearLimit => 'Cerca del límite',
            BudgetHealthStatus.onTrack => 'En curso',
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(HitoSpacing.sm + HitoSpacing.xs),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: onPrimary.withValues(alpha: 0.8))),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Aviso suave, sin castigo — mismo tono que el resto de la app frente
/// a "malas noticias" (nunca alarmante, siempre con una salida).
class _HealthBanner extends StatelessWidget {
  const _HealthBanner({required this.health});

  final BudgetHealthStatus health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exceeded = health == BudgetHealthStatus.exceeded;
    final bg = exceeded ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer;
    final fg = exceeded ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer;
    final message = exceeded
        ? 'Superaste tu límite. Podés ajustar el presupuesto o revisar tus gastos, sin drama.'
        : 'Estás cerca del límite — respirá y revisá tus gastos antes de que llegue la fecha.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(HitoRadius.md)),
      child: Row(
        children: [
          Icon(
            exceeded ? Icons.error_outline : Icons.info_outline,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroups extends StatelessWidget {
  const _CategoryGroups({required this.budget, required this.progress, required this.onReassign});

  final Budget budget;
  final BudgetProgress progress;
  final ValueChanged<BudgetCategoryAllocation> onReassign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = <BudgetCategoryAllocation>[];
    final onTrack = <BudgetCategoryAllocation>[];
    for (final c in budget.categories) {
      final health = budgetHealthFor(progress.spentFor(c.categoryId), c.limitAmount);
      (health == BudgetHealthStatus.onTrack ? onTrack : urgent).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (urgent.isNotEmpty) ...[
          Text('Atención inmediata', style: theme.textTheme.headlineMedium),
          const SizedBox(height: HitoSpacing.sm),
          for (final c in urgent) ...[
            _CategoryProgressRow(
              allocation: c,
              spent: progress.spentFor(c.categoryId),
              onReassign: () => onReassign(c),
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
          const SizedBox(height: HitoSpacing.sm),
        ],
        if (onTrack.isNotEmpty) ...[
          Text('Bajo control', style: theme.textTheme.headlineMedium),
          const SizedBox(height: HitoSpacing.sm),
          for (final c in onTrack) ...[
            _CategoryProgressRow(allocation: c, spent: progress.spentFor(c.categoryId)),
            const SizedBox(height: HitoSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({required this.allocation, required this.spent, this.onReassign});

  final BudgetCategoryAllocation allocation;
  final double spent;

  /// Solo se pasa para categorías en "Atención inmediata" — ahí es
  /// donde tiene sentido ofrecer mover fondos desde otra con sobrante.
  final VoidCallback? onReassign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = findCategory(allocation.categoryId);
    final health = budgetHealthFor(spent, allocation.limitAmount);
    final ratio = allocation.limitAmount <= 0 ? 0.0 : (spent / allocation.limitAmount).clamp(0.0, 1.0);
    final color = switch (health) {
      BudgetHealthStatus.exceeded => theme.colorScheme.error,
      BudgetHealthStatus.nearLimit => HitoColors.warningLight,
      BudgetHealthStatus.onTrack => theme.colorScheme.primary,
    };

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: theme.colorScheme.secondaryContainer, shape: BoxShape.circle),
                child: Icon(
                  category?.icon ?? Icons.category_outlined,
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: HitoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          allocation.categoryLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${formatCurrency(spent)} / ${formatCurrency(allocation.limitAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HitoSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: recessedColor(theme),
                              color: color,
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
                  ],
                ),
              ),
            ],
          ),
          if (onReassign != null) ...[
            const SizedBox(height: HitoSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReassign,
                icon: const Icon(Icons.sync_alt, size: 16),
                label: const Text('Reasignar fondos'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReassignResult {
  const _ReassignResult({required this.fromCategoryId, required this.amount});

  final String fromCategoryId;
  final double amount;
}

/// Elegir de dónde sacar fondos (categorías con sobrante) y cuánto
/// mover hacia la categoría excedida — "mover todo" o un monto parcial.
class _ReassignFundsSheet extends StatefulWidget {
  const _ReassignFundsSheet({
    required this.target,
    required this.candidates,
    required this.progress,
  });

  final BudgetCategoryAllocation target;
  final List<BudgetCategoryAllocation> candidates;
  final BudgetProgress progress;

  @override
  State<_ReassignFundsSheet> createState() => _ReassignFundsSheetState();
}

class _ReassignFundsSheetState extends State<_ReassignFundsSheet> {
  BudgetCategoryAllocation? _selected;
  late final _amountController = TextEditingController();

  double get _surplus =>
      _selected == null ? 0 : _selected!.limitAmount - widget.progress.spentFor(_selected!.categoryId);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectAll(BudgetCategoryAllocation c) {
    setState(() {
      _selected = c;
      final surplus = c.limitAmount - widget.progress.spentFor(c.categoryId);
      _amountController.text = surplus.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final canConfirm = _selected != null && amount > 0 && amount <= _surplus;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(HitoSpacing.lg, HitoSpacing.sm, HitoSpacing.lg, HitoSpacing.lg),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(HitoRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(height: HitoSpacing.md),
                Text('Reasignar fondos', style: theme.textTheme.headlineMedium),
                const SizedBox(height: HitoSpacing.xs),
                Text(
                  'Mové sobrante de otra categoría hacia "${widget.target.categoryLabel}".',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: HitoSpacing.md),
                for (final c in widget.candidates) ...[
                  _SurplusCategoryTile(
                    allocation: c,
                    surplus: c.limitAmount - widget.progress.spentFor(c.categoryId),
                    selected: _selected?.categoryId == c.categoryId,
                    onTap: () => _selectAll(c),
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                ],
                if (_selected != null) ...[
                  const SizedBox(height: HitoSpacing.sm),
                  Text(
                    'Monto a mover (máximo ${formatCurrency(_surplus)})',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: HitoSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
                    decoration: BoxDecoration(
                      color: recessedColor(theme),
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canConfirm
                        ? () => Navigator.of(context).pop(
                              _ReassignResult(fromCategoryId: _selected!.categoryId, amount: amount),
                            )
                        : null,
                    child: const Text('Mover fondos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurplusCategoryTile extends StatelessWidget {
  const _SurplusCategoryTile({
    required this.allocation,
    required this.surplus,
    required this.selected,
    required this.onTap,
  });

  final BudgetCategoryAllocation allocation;
  final double surplus;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: Container(
        padding: const EdgeInsets.all(HitoSpacing.md),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : recessedColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              findCategory(allocation.categoryId)?.icon ?? Icons.category_outlined,
              size: 20,
              color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Text(
                allocation.categoryLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              ),
            ),
            Text(
              'Sobran ${formatCurrency(surplus)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumen final una vez pasada la fecha límite — total gastado,
/// categorías equilibradas vs. excedidas, y las acciones para seguir
/// (nunca deja al usuario sin salida).
class _ClosedBudgetSummary extends StatelessWidget {
  const _ClosedBudgetSummary({
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
    final balanced = budget.categories
        .where((c) => budgetHealthFor(progress.spentFor(c.categoryId), c.limitAmount) == BudgetHealthStatus.onTrack)
        .length;
    final exceeded = budget.categories.length - balanced;
    final ratio =
        budget.limitAmount <= 0 ? 0.0 : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(HitoSpacing.lg, HitoSpacing.md, HitoSpacing.lg, HitoSpacing.xxl),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HitoSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(32),
            boxShadow: heroShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRESUPUESTO CERRADO',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: HitoSpacing.xs),
              Text(
                formatCurrency(progress.spentTotal),
                style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary),
              ),
              Text(
                'de ${formatCurrency(budget.limitAmount)} límite (${(ratio * 100).round()}%)',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: HitoSpacing.md),
        if (budget.type == BudgetType.byCategory && budget.categories.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Categorías equilibradas',
                  value: '$balanced',
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Expanded(
                child: _SummaryStatCard(
                  icon: Icons.error_outline,
                  label: 'Categorías excedidas',
                  value: '$exceeded',
                ),
              ),
            ],
          ),
        const SizedBox(height: HitoSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () =>
                openCreateBudgetScreen(context, repository: budgetsRepository, duplicateFrom: budget),
            child: const Text('Duplicar este presupuesto'),
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => openCreateBudgetScreen(context, repository: budgetsRepository),
            child: const Text('Crear presupuesto nuevo'),
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => openBudgetHistoryScreen(
              context,
              budgetsRepository: budgetsRepository,
              transactionsRepository: transactionsRepository,
            ),
            child: const Text('Ver historial de presupuestos'),
          ),
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
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
          Icon(icon, size: 20, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(height: HitoSpacing.sm),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
