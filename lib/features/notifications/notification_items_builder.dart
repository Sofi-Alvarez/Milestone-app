import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../data/notification_item.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../data/user_settings.dart';

/// Combina las fuentes reales de notificaciones en una sola lista
/// ordenada, respetando qué tipos activó el usuario en Perfil — usado
/// tanto por la pantalla de Notificaciones como por el indicador de
/// "no leídas" en la campana del Home.
class NotificationItemsBuilder extends StatelessWidget {
  const NotificationItemsBuilder({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.builder,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;
  final Widget Function(BuildContext context, List<NotificationItem> items) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserSettings>(
      stream: settingsRepository.watchSettings(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data ?? UserSettings.empty;

        return StreamBuilder<List<Goal>>(
          stream: goalsRepository.watchGoals(),
          builder: (context, goalsSnapshot) {
            final achieved = (goalsSnapshot.data ?? const <Goal>[])
                .where((g) => g.lifecycle == GoalLifecycle.achieved && g.achievedAt != null)
                .toList();

            return StreamBuilder<List<ScheduledPayment>>(
              stream: transactionsRepository.watchDueScheduledPayments(),
              builder: (context, dueSnapshot) {
                final due = dueSnapshot.data ?? const <ScheduledPayment>[];

                return StreamBuilder<double>(
                  stream: transactionsRepository.watchBalance(),
                  builder: (context, balanceSnapshot) {
                    final balance = balanceSnapshot.data;

                    return StreamBuilder<List<MoneyTransaction>>(
                      stream: transactionsRepository.watchTransactions(limit: 200),
                      builder: (context, txSnapshot) {
                        final transactions = txSnapshot.data;
                        final items = <NotificationItem>[
                          if (settings.notifySavingsGoals)
                            for (final goal in achieved) NotificationItem.achievedGoal(goal),
                          for (final payment in due) NotificationItem.duePayment(payment),
                          if (settings.notifySpendingAlerts && balance != null && balance < 0)
                            NotificationItem.lowBalance(),
                          if (transactions != null)
                            ..._deriveFromTransactions(transactions, settings),
                        ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                        return builder(context, items);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<NotificationItem> _deriveFromTransactions(
    List<MoneyTransaction> transactions,
    UserSettings settings,
  ) {
    final items = <NotificationItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTransactions = transactions.where((t) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      return d == today;
    }).toList();

    if (settings.notifyDailySummary && todayTransactions.isNotEmpty) {
      final income = todayTransactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final expense = todayTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);
      items.add(NotificationItem.dailySummary(income: income, expense: expense));
    }

    if (settings.notifyRegisterReminder) {
      if (transactions.isEmpty) {
        items.add(NotificationItem.registerReminder(-1));
      } else {
        final lastDate = transactions
            .map((t) => t.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final daysSince = today.difference(lastDay).inDays;
        if (daysSince >= 1) {
          items.add(NotificationItem.registerReminder(daysSince));
        }
      }
    }

    return items;
  }
}
