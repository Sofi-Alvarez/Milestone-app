import 'package:flutter/material.dart';

import '../../data/goals_repository.dart';
import '../../data/movement.dart';
import '../../data/notification_item.dart';
import '../../data/notifications_read_state.dart';
import '../../data/transactions_repository.dart';
import '../../data/user_settings.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'notification_items_builder.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(title: const Text('Notificaciones'), centerTitle: false),
      body: NotificationItemsBuilder(
        goalsRepository: goalsRepository,
        transactionsRepository: transactionsRepository,
        settingsRepository: settingsRepository,
        builder: (context, items) {
          return ValueListenableBuilder<DateTime?>(
            valueListenable: NotificationsReadState.instance.lastReadAt,
            builder: (context, lastReadAt, _) {
              final hasUnread = items.any(
                (item) => lastReadAt == null || item.timestamp.isAfter(lastReadAt),
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      HitoSpacing.lg,
                      HitoSpacing.sm,
                      HitoSpacing.lg,
                      HitoSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: hasUnread
                            ? () => NotificationsReadState.instance.markAllRead()
                            : null,
                        child: const Text('Marcar todo como leído'),
                      ),
                    ),
                  ),
                  Expanded(child: _NotificationsList(items: items)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: HitoSpacing.sm),
        children: [
          for (final item in items) ...[
            _NotificationTile(item: item),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ],
          const SizedBox(height: HitoSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.lg),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: HitoSpacing.sm),
                Text(
                  'No hay más notificaciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (icon, iconColor, title, body) = switch (item.kind) {
      NotificationKind.achievedGoal => (
          Icons.check,
          isDark ? HitoColors.successDark : HitoColors.successLight,
          'Ahorro alcanzado',
          '¡Felicidades! Has alcanzado tu meta de ahorro para '
              '"${item.goal!.title}". Has acumulado ${formatCurrency(item.goal!.targetAmount)}.',
        ),
      NotificationKind.duePayment => (
          Icons.schedule_outlined,
          theme.colorScheme.primary,
          'Registro pendiente',
          'Tenés "${item.payment!.name}" para registrar: '
              '${formatCurrency(item.payment!.amount)} en ${item.payment!.categoryLabel}. '
              'Aceptalo o reprogramalo desde el Home.',
        ),
      NotificationKind.lowBalance => (
          Icons.warning_amber_outlined,
          theme.colorScheme.error,
          'Saldo por debajo del mínimo',
          'Tu dinero disponible es negativo. Registrá tus ingresos o '
              'revisá tus gastos recientes.',
        ),
      NotificationKind.registerReminder => (
          Icons.edit_note_outlined,
          theme.colorScheme.secondary,
          'Recordatorio para registrar',
          item.daysSinceLastRegister! < 0
              ? 'Todavía no registraste ningún ingreso o gasto. ¡Empezá hoy!'
              : item.daysSinceLastRegister == 1
                  ? 'Hace 1 día que no registrás ningún movimiento.'
                  : 'Hace ${item.daysSinceLastRegister} días que no registrás ningún movimiento.',
        ),
      NotificationKind.dailySummary => (
          Icons.summarize_outlined,
          theme.colorScheme.tertiary,
          'Resumen del día',
          'Hoy registraste ${formatCurrency(item.todayIncome!)} en ingresos y '
              '${formatCurrency(item.todayExpense!)} en gastos.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HitoSpacing.lg,
        vertical: HitoSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatRelativeTime(item.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
