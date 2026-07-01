import 'goal.dart';
import 'transaction.dart';

enum NotificationKind {
  achievedGoal,
  duePayment,
  lowBalance,
  registerReminder,
  dailySummary,
}

/// Cinco fuentes reales, sin nada inventado: metas logradas, registros
/// planificados vencidos, saldo por debajo del mínimo, recordatorio si
/// hace tiempo que no registrás nada, y resumen del día si hoy sí
/// registraste. Cada una se puede apagar desde Perfil.
class NotificationItem {
  const NotificationItem._(
    this.kind,
    this.timestamp, {
    this.goal,
    this.payment,
    this.daysSinceLastRegister,
    this.todayIncome,
    this.todayExpense,
  });

  factory NotificationItem.achievedGoal(Goal goal) =>
      NotificationItem._(NotificationKind.achievedGoal, goal.achievedAt!, goal: goal);

  factory NotificationItem.duePayment(ScheduledPayment payment) => NotificationItem._(
        NotificationKind.duePayment,
        payment.nextDueDate,
        payment: payment,
      );

  // Sin timestamp real propio — es un estado actual, no un evento
  // puntual, así que usamos "ahora" para que aparezca primero.
  factory NotificationItem.lowBalance() =>
      NotificationItem._(NotificationKind.lowBalance, DateTime.now());

  factory NotificationItem.registerReminder(int daysSinceLastRegister) => NotificationItem._(
        NotificationKind.registerReminder,
        DateTime.now(),
        daysSinceLastRegister: daysSinceLastRegister,
      );

  factory NotificationItem.dailySummary({required double income, required double expense}) =>
      NotificationItem._(
        NotificationKind.dailySummary,
        DateTime.now(),
        todayIncome: income,
        todayExpense: expense,
      );

  final NotificationKind kind;
  final DateTime timestamp;
  final Goal? goal;
  final ScheduledPayment? payment;
  final int? daysSinceLastRegister;
  final double? todayIncome;
  final double? todayExpense;
}
