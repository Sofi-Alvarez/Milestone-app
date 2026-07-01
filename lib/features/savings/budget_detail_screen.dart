import 'dart:math';

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
import 'widgets/budget_status_pill.dart';
import 'widgets/goal_form_fields.dart';

void openBudgetDetailScreen(
  BuildContext context, {
  required BudgetsRepository budgetsRepository,
  required TransactionsRepository transactionsRepository,
  required Budget budget,
  BudgetProgress? exampleProgress,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BudgetDetailScreen(
        budgetsRepository: budgetsRepository,
        transactionsRepository: transactionsRepository,
        budget: budget,
        exampleProgress: exampleProgress,
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
    this.exampleProgress,
  });

  final BudgetsRepository budgetsRepository;
  final TransactionsRepository transactionsRepository;
  final Budget budget;

  /// Si viene seteado, la pantalla usa este progreso fijo y desactiva
  /// las acciones que escriben en Firestore ("Editar", "Reasignar",
  /// "Pausar", "Cancelar") — es el modo "Cargar un ejemplo".
  final BudgetProgress? exampleProgress;

  bool get isExample => exampleProgress != null;

  Future<void> _pause(BuildContext context) async {
    final resume = budget.status == BudgetStatus.paused;
    if (resume) {
      await budgetsRepository.resumeBudget(budget.id);
    } else {
      await budgetsRepository.pauseBudget(budget.id);
    }
    if (context.mounted) {
      showAppSnackBar(
        context,
        resume
            ? 'Presupuesto reactivado'
            : 'Presupuesto pausado — los gastos de acá en más no se van a contar hasta que lo reactivés',
      );
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

  Budget _withCategories(List<BudgetCategoryAllocation> categories) => _copyWith(categories: categories);

  Budget _withLimit(double limitAmount) => _copyWith(limitAmount: limitAmount);

  Budget _copyWith({List<BudgetCategoryAllocation>? categories, double? limitAmount}) => Budget(
    id: budget.id,
    name: budget.name,
    type: budget.type,
    limitAmount: limitAmount ?? budget.limitAmount,
    startDate: budget.startDate,
    endDate: budget.endDate,
    note: budget.note,
    notifyExceeded: budget.notifyExceeded,
    notifyNearLimit: budget.notifyNearLimit,
    status: budget.status,
    categories: categories ?? budget.categories,
    createdAt: budget.createdAt,
    pausedAt: budget.pausedAt,
    resumedAt: budget.resumedAt,
  );

  /// Atajo para "Presupuesto general": ajustar el límite con +/- sin
  /// pasar por el wizard completo de edición.
  Future<void> _quickAdjustLimit(BuildContext context) async {
    final newLimit = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickAdjustLimitSheet(currentLimit: budget.limitAmount),
    );
    if (newLimit == null || !context.mounted) return;
    try {
      await budgetsRepository.updateBudget(budget.id, _withLimit(newLimit));
      if (context.mounted) showAppSnackBar(context, 'Límite actualizado');
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'No pudimos actualizar el límite: $e', isError: true);
      }
    }
  }

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
      builder: (_) => _ReassignFundsSheet(
        target: target,
        candidates: candidates,
        progress: progress,
      ),
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
        showAppSnackBar(
          context,
          'No pudimos reasignar los fondos: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(budget.name),
            Text(
              'Vence ${formatGoalDate(budget.endDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: isExample
            ? _buildContent(context, exampleProgress!)
            : StreamBuilder<List<MoneyTransaction>>(
                stream: transactionsRepository.watchTransactions(limit: 500),
                builder: (context, snapshot) {
                  final transactions =
                      snapshot.data ?? const <MoneyTransaction>[];
                  return _buildContent(
                    context,
                    computeBudgetProgress(budget, transactions),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BudgetProgress progress) {
    final theme = Theme.of(context);
    final health = budgetHealthFor(progress.spentTotal, budget.limitAmount);
    final ratio = budget.limitAmount <= 0
        ? 0.0
        : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);
    final remaining = budget.limitAmount - progress.spentTotal;

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
        _GaugeCard(
          ratio: ratio,
          health: health,
          status: budget.status,
          spentTotal: progress.spentTotal,
          remaining: remaining,
          limitAmount: budget.limitAmount,
          daysLeft: budget.isPastEnd ? 'Vencido' : '${budget.daysLeft} días',
        ),
        const SizedBox(height: HitoSpacing.md),
        _DetailBanner(health: health, hasSpending: progress.spentTotal > 0),
        if (budget.type == BudgetType.byCategory &&
            budget.categories.isNotEmpty) ...[
          const SizedBox(height: HitoSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categorías', style: theme.textTheme.headlineMedium),
              if (!isExample)
                TextButton(
                  onPressed: () => openCreateBudgetScreen(
                    context,
                    repository: budgetsRepository,
                    existingBudget: budget,
                  ),
                  child: const Text('Editar'),
                ),
            ],
          ),
          const SizedBox(height: HitoSpacing.sm),
          for (final c in budget.categories) ...[
            _CategoryDetailRow(
              allocation: c,
              spent: progress.spentFor(c.categoryId),
              onReassign:
                  (!isExample &&
                      budgetHealthFor(
                            progress.spentFor(c.categoryId),
                            c.limitAmount,
                          ) !=
                          BudgetHealthStatus.onTrack)
                  ? () => _reassignFunds(context, progress, c)
                  : null,
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
          if (progress.unassignedSpent(budget) > 0)
            _UnassignedSpendRow(amount: progress.unassignedSpent(budget)),
        ],
        const SizedBox(height: HitoSpacing.lg),
        if (isExample)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.md),
            decoration: BoxDecoration(
              color: recessedColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: Text(
                    'Esto es un presupuesto de ejemplo — creá el tuyo para poder editarlo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text('Acciones', style: theme.textTheme.headlineMedium),
          const SizedBox(height: HitoSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
              boxShadow: cardShadow(),
            ),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.edit_outlined,
                  label: 'Editar presupuesto',
                  onTap: () => openCreateBudgetScreen(
                    context,
                    repository: budgetsRepository,
                    existingBudget: budget,
                  ),
                ),
                if (budget.type == BudgetType.general) ...[
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  _ActionRow(
                    icon: Icons.tune,
                    label: 'Ajustar límite',
                    onTap: () => _quickAdjustLimit(context),
                  ),
                ],
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                _ActionRow(
                  icon: budget.status == BudgetStatus.paused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  label: budget.status == BudgetStatus.paused
                      ? 'Reanudar presupuesto'
                      : 'Pausar presupuesto',
                  onTap: () => _pause(context),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                _ActionRow(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelar presupuesto',
                  labelColor: theme.colorScheme.error,
                  onTap: () => _cancel(context),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                _ActionRow(
                  icon: Icons.copy_outlined,
                  label: 'Duplicar como nuevo presupuesto',
                  onTap: () => openCreateBudgetScreen(
                    context,
                    repository: budgetsRepository,
                    duplicateFrom: budget,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Card única con el estado del presupuesto: pastilla de estado
/// arriba a la derecha, gauge circular "% usado" centrado, y la
/// grilla 2x2 de estadísticas debajo — todo dentro del mismo
/// contenedor (antes eran piezas sueltas con sombras propias que se
/// superponían mal).
class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.ratio,
    required this.health,
    required this.status,
    required this.spentTotal,
    required this.remaining,
    required this.limitAmount,
    required this.daysLeft,
  });

  final double ratio;
  final BudgetHealthStatus health;
  final BudgetStatus status;
  final double spentTotal;
  final double remaining;
  final double limitAmount;
  final String daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressColorFor(context, health);
    final pillHealth = status == BudgetStatus.paused ? BudgetHealthStatus.onTrack : health;
    final pillLabel = status == BudgetStatus.paused
        ? 'Pausado'
        : switch (health) {
            BudgetHealthStatus.exceeded => 'Excedido',
            BudgetHealthStatus.nearLimit => 'Cerca del límite',
            BudgetHealthStatus.onTrack => 'En curso',
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(28),
        boxShadow: cardShadow(),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: BudgetStatusPill(label: pillLabel, health: pillHealth),
          ),
          const SizedBox(height: HitoSpacing.sm),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _GaugePainter(ratio: ratio, color: color, track: recessedColor(theme)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(ratio * 100).round()}%',
                      style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'usado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: HitoSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: HitoSpacing.sm,
            crossAxisSpacing: HitoSpacing.sm,
            childAspectRatio: 2.4,
            children: [
              _StatChip(label: 'Gastado', value: formatCurrency(spentTotal)),
              _StatChip(
                label: remaining >= 0 ? 'Disponible' : 'Excedido por',
                value: formatCurrency(remaining.abs()),
              ),
              _StatChip(label: 'Límite', value: formatCurrency(limitAmount)),
              _StatChip(label: 'Restan', value: daysLeft),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.ratio,
    required this.color,
    required this.track,
  });

  final double ratio;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 14.0;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 2 * pi, false, trackPaint);

    if (ratio <= 0) return;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -pi / 2,
      2 * pi * ratio.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.color != color;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ajuste rápido del límite de un presupuesto general — botones +/-
/// de $5.000 y un campo directo, sin pasar por el wizard completo.
class _QuickAdjustLimitSheet extends StatefulWidget {
  const _QuickAdjustLimitSheet({required this.currentLimit});

  final double currentLimit;

  @override
  State<_QuickAdjustLimitSheet> createState() => _QuickAdjustLimitSheetState();
}

class _QuickAdjustLimitSheetState extends State<_QuickAdjustLimitSheet> {
  static const _step = 5000.0;
  late final _controller = TextEditingController(
    text: formatCurrency(widget.currentLimit).replaceAll('\$', ''),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _value => parseAmountInput(_controller.text);

  void _adjust(double delta) {
    final next = (_value + delta).clamp(0.0, double.infinity);
    setState(() => _controller.text = next.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text('Ajustar límite', style: theme.textTheme.headlineMedium),
              const SizedBox(height: HitoSpacing.md),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _adjust(-_step),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: HitoSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
                      decoration: BoxDecoration(
                        color: recessedColor(theme),
                        borderRadius: BorderRadius.circular(HitoRadius.md),
                      ),
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: theme.textTheme.headlineMedium,
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          prefixText: '\$ ',
                          contentPadding: EdgeInsets.symmetric(vertical: HitoSpacing.md),
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _adjust(_step),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _value > 0 ? () => Navigator.of(context).pop(_value) : null,
                  child: const Text('Guardar límite'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gastos registrados en categorías que no tienen asignación en este
/// presupuesto — igual descuentan del límite general (por eso su
/// monto ya está sumado en "Gastado"), pero no pertenecen a ninguna
/// barra de categoría, así que se etiquetan acá aparte.
class _UnassignedSpendRow extends StatelessWidget {
  const _UnassignedSpendRow({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.sm + 4),
      decoration: BoxDecoration(
        color: recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: cardColor(theme), shape: BoxShape.circle),
            child: Icon(Icons.help_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuera de categoría asignada',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Igual descuenta del límite general',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            formatCurrencyCompact(amount),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailBanner extends StatelessWidget {
  const _DetailBanner({required this.health, required this.hasSpending});

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

class _CategoryDetailRow extends StatelessWidget {
  const _CategoryDetailRow({
    required this.allocation,
    required this.spent,
    this.onReassign,
  });

  final BudgetCategoryAllocation allocation;
  final double spent;
  final VoidCallback? onReassign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = findCategory(allocation.categoryId);
    final health = budgetHealthFor(spent, allocation.limitAmount);
    final ratio = allocation.limitAmount <= 0
        ? 0.0
        : (spent / allocation.limitAmount).clamp(0.0, 1.0);
    final pillLabel = spent == 0
        ? 'Sin movimientos'
        : switch (health) {
            BudgetHealthStatus.exceeded => 'Excedido',
            BudgetHealthStatus.nearLimit => 'Cerca del límite',
            BudgetHealthStatus.onTrack => 'En curso',
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.sm + 4),
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
                  category?.icon ?? Icons.category_outlined,
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
                    borderRadius: BorderRadius.circular(9999),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HitoSpacing.md,
          vertical: HitoSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: labelColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
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

  double get _surplus => _selected == null
      ? 0
      : _selected!.limitAmount -
            widget.progress.spentFor(_selected!.categoryId);

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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          HitoSpacing.lg,
          HitoSpacing.sm,
          HitoSpacing.lg,
          HitoSpacing.lg,
        ),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: HitoSpacing.md),
                for (final c in widget.candidates) ...[
                  _SurplusCategoryTile(
                    allocation: c,
                    surplus:
                        c.limitAmount - widget.progress.spentFor(c.categoryId),
                    selected: _selected?.categoryId == c.categoryId,
                    onTap: () => _selectAll(c),
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                ],
                if (_selected != null) ...[
                  const SizedBox(height: HitoSpacing.sm),
                  Text(
                    'Monto a mover (máximo ${formatCurrency(_surplus)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: HitoSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HitoSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: recessedColor(theme),
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                            _ReassignResult(
                              fromCategoryId: _selected!.categoryId,
                              amount: amount,
                            ),
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
          color: selected
              ? theme.colorScheme.primaryContainer
              : recessedColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              findCategory(allocation.categoryId)?.icon ??
                  Icons.category_outlined,
              size: 20,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
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
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
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
        .where(
          (c) =>
              budgetHealthFor(progress.spentFor(c.categoryId), c.limitAmount) ==
              BudgetHealthStatus.onTrack,
        )
        .length;
    final exceeded = budget.categories.length - balanced;
    final ratio = budget.limitAmount <= 0
        ? 0.0
        : (progress.spentTotal / budget.limitAmount).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        HitoSpacing.lg,
        HitoSpacing.md,
        HitoSpacing.lg,
        HitoSpacing.xxl,
      ),
      children: [
        _GaugeCard(
          ratio: ratio,
          health: budgetHealthFor(progress.spentTotal, budget.limitAmount),
          status: budget.status,
          spentTotal: progress.spentTotal,
          remaining: budget.limitAmount - progress.spentTotal,
          limitAmount: budget.limitAmount,
          daysLeft: 'Vencido',
        ),
        const SizedBox(height: HitoSpacing.md),
        Center(
          child: Text(
            '${formatCurrency(progress.spentTotal)} de ${formatCurrency(budget.limitAmount)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: HitoSpacing.md),
        if (budget.type == BudgetType.byCategory &&
            budget.categories.isNotEmpty)
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
            onPressed: () => openCreateBudgetScreen(
              context,
              repository: budgetsRepository,
              duplicateFrom: budget,
            ),
            child: const Text('Duplicar este presupuesto'),
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                openCreateBudgetScreen(context, repository: budgetsRepository),
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
  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

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
