import '../../data/budget.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';

/// Gasto acumulado de un presupuesto contra las transacciones reales
/// del período — nunca se persiste, se calcula en vivo cada vez.
class BudgetProgress {
  const BudgetProgress({required this.spentTotal, required this.spentByCategory});

  final double spentTotal;
  final Map<String, double> spentByCategory;

  double spentFor(String categoryId) => spentByCategory[categoryId] ?? 0;
}

BudgetProgress computeBudgetProgress(Budget budget, List<MoneyTransaction> transactions) {
  final relevant = transactions.where(
    (t) =>
        t.type == TransactionType.expense &&
        !t.date.isBefore(budget.startDate) &&
        !t.date.isAfter(budget.endDate),
  );
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
