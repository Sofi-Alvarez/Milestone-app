import '../../data/budget.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';

/// Gasto acumulado de un presupuesto contra las transacciones reales
/// del período — nunca se persiste, se calcula en vivo cada vez.
class BudgetProgress {
  const BudgetProgress({
    required this.spentTotal,
    required this.spentByCategory,
  });

  final double spentTotal;
  final Map<String, double> spentByCategory;

  double spentFor(String categoryId) => spentByCategory[categoryId] ?? 0;

  /// Gasto en categorías que no tienen una asignación en el
  /// presupuesto — un gasto real que igual descuenta del límite
  /// general, pero no pertenece a ninguna barra de categoría.
  double unassignedSpent(Budget budget) {
    final allocatedIds = budget.categories.map((c) => c.categoryId).toSet();
    return spentByCategory.entries
        .where((e) => !allocatedIds.contains(e.key))
        .fold(0.0, (sum, e) => sum + e.value);
  }
}

BudgetProgress computeBudgetProgress(
  Budget budget,
  List<MoneyTransaction> transactions,
) {
  final relevant = transactions.where((t) {
    if (t.type != TransactionType.expense) return false;
    if (t.date.isBefore(budget.startDate) || t.date.isAfter(budget.endDate))
      return false;
    // Ventana "congelada": mientras el presupuesto estuvo pausado, los
    // gastos hechos en ese lapso no cuentan — ni ahora ni si se
    // reanuda más tarde.
    if (budget.pausedAt != null) {
      final freezeStart = budget.pausedAt!;
      final freezeEnd = budget.status == BudgetStatus.paused
          ? DateTime.now()
          : (budget.resumedAt ?? budget.pausedAt!);
      if (!t.date.isBefore(freezeStart) && !t.date.isAfter(freezeEnd))
        return false;
    }
    return true;
  });
  var total = 0.0;
  final byCategory = <String, double>{};
  for (final t in relevant) {
    total += t.amount;
    byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
  }
  return BudgetProgress(spentTotal: total, spentByCategory: byCategory);
}

enum BudgetHealthStatus { onTrack, nearLimit, exceeded }

/// >=100% del límite es excedido, >=85% es "cerca del límite" (entra en
/// "Atención inmediata"), el resto está bajo control.
BudgetHealthStatus budgetHealthFor(double spent, double limit) {
  if (limit <= 0) return BudgetHealthStatus.onTrack;
  final ratio = spent / limit;
  if (ratio >= 1) return BudgetHealthStatus.exceeded;
  if (ratio >= 0.85) return BudgetHealthStatus.nearLimit;
  return BudgetHealthStatus.onTrack;
}
