import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../data/movement.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../data/user_settings.dart';
import '../../theme/app_theme.dart';
import '../../data/notifications_read_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/card_strike_through.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/stat_value.dart';
import '../../widgets/transaction_icon_avatar.dart';
import '../history/scheduled_detail_sheet.dart';
import '../history/transaction_detail_sheet.dart';
import '../notifications/notification_items_builder.dart';
import '../notifications/notifications_screen.dart';
import '../savings/create_goal_screen.dart';
import '../savings/goal_detail_screen.dart';
import '../savings/widgets/goal_form_fields.dart';
import 'models/home_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.onViewHistory,
    required this.onOpenSavings,
    required this.onOpenHistoryStats,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;

  /// Lleva a la pestaña de Historial — ahí se podrán ver y editar todos
  /// los registros, incluso los programados.
  final VoidCallback onViewHistory;

  /// "Ahorro mensual" lleva a Ahorro (vista de Metas).
  final VoidCallback onOpenSavings;

  /// "Dinero disponible" lleva a Historial (vista de Estadística).
  final VoidCallback onOpenHistoryStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // El sheet de abajo pinta "surface" sobre esto; el primary solo debe
      // verse en la curva de los bordes superiores redondeados del sheet.
      backgroundColor: theme.colorScheme.primary,
      body: StreamBuilder<List<Goal>>(
        stream: goalsRepository.watchGoals(),
        builder: (context, goalsSnapshot) {
          if (!goalsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = goalsSnapshot.data!;
          final active = goals
              .where((g) => g.lifecycle == GoalLifecycle.active)
              .toList();

          Goal? featured;
          for (final g in active) {
            if (g.targetDate == null) continue;
            if (featured == null ||
                g.targetDate!.isBefore(featured.targetDate!)) {
              featured = g;
            }
          }
          featured ??= active.isNotEmpty ? active.first : null;

          return StreamBuilder<List<Movement>>(
            stream: goalsRepository.watchMovementsThisMonth(),
            builder: (context, monthSnapshot) {
              final monthMovements = monthSnapshot.data ?? const <Movement>[];
              final monthlySavings = monthMovements.fold<double>(
                0,
                (sum, m) => sum + m.amount,
              );

              return SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Fila fija tipo app bar — no se mueve con el scroll,
                    // a diferencia de todo lo que está debajo.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        HitoSpacing.lg,
                        HitoSpacing.sm,
                        HitoSpacing.lg,
                        HitoSpacing.sm,
                      ),
                      color: theme.colorScheme.primary,
                      child: Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<UserSettings>(
                              stream: settingsRepository.watchSettings(),
                              builder: (context, settingsSnapshot) {
                                final name = settingsSnapshot.data?.name ?? '';
                                return Text(
                                  name.isEmpty
                                      ? 'Bienvenido'
                                      : 'Bienvenido, $name',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                );
                              },
                            ),
                          ),
                          _NotificationsBell(
                            goalsRepository: goalsRepository,
                            transactionsRepository: transactionsRepository,
                            settingsRepository: settingsRepository,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // El fondo primary se extiende hasta abajo de la
                                    // card jerárquica — el "sheet" de abajo (fondo
                                    // base, esquinas superiores redondeadas) es lo
                                    // que visualmente corta la transición.
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        HitoSpacing.lg,
                                        0,
                                        HitoSpacing.lg,
                                        HitoSpacing.md,
                                      ),
                                      color: theme.colorScheme.primary,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tu progreso actual',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                          ),
                                          Text(
                                            active.isNotEmpty
                                                ? 'Metas activas'
                                                : 'Metas inactivas',
                                            style: theme.textTheme.headlineLarge
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: HitoSpacing.lg,
                                          ),
                                          _FeaturedGoalCard(
                                            goal: featured,
                                            onPrimaryAction: () {
                                              if (featured == null) {
                                                openCreateGoalScreen(
                                                  context,
                                                  repository: goalsRepository,
                                                );
                                              } else {
                                                openGoalDetail(
                                                  context,
                                                  repository: goalsRepository,
                                                  goal: featured,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: pageColor(theme),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(
                                              HitoRadius.lg,
                                            ),
                                            topRight: Radius.circular(
                                              HitoRadius.lg,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          HitoSpacing.lg,
                                          HitoSpacing.md,
                                          HitoSpacing.lg,
                                          HitoSpacing.lg,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: StatValue(
                                                    label: 'Ahorro mensual',
                                                    // Nunca mostrar "$0,00" — sin actividad
                                                    // este mes, es "sin datos", no cero.
                                                    value:
                                                        monthMovements.isEmpty
                                                        ? 'Sin datos'
                                                        : formatCurrency(
                                                            monthlySavings,
                                                          ),
                                                    background: theme
                                                        .colorScheme
                                                        .primaryContainer,
                                                    foreground: theme
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    onTap: onOpenSavings,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: HitoSpacing.sm,
                                                ),
                                                // "Dinero disponible" = ingresos
                                                // menos gastos registrados en
                                                // Registrar. Si no hay ningún
                                                // registro todavía es "Sin datos",
                                                // no "$0,00" (balance real distinto
                                                // de ausencia de datos).
                                                Expanded(
                                                  child: StreamBuilder<List<MoneyTransaction>>(
                                                    stream:
                                                        transactionsRepository
                                                            .watchTransactions(),
                                                    builder: (context, txSnapshot) {
                                                      final transactions =
                                                          txSnapshot.data ??
                                                          const <
                                                            MoneyTransaction
                                                          >[];
                                                      final balance =
                                                          transactions.fold<
                                                            double
                                                          >(
                                                            0,
                                                            (total, t) =>
                                                                total +
                                                                t.signedAmount,
                                                          );
                                                      return StatValue(
                                                        label:
                                                            'Dinero disponible',
                                                        value:
                                                            transactions.isEmpty
                                                            ? 'Sin datos'
                                                            : formatCurrency(
                                                                balance,
                                                              ),
                                                        background: theme
                                                            .colorScheme
                                                            .primaryContainer,
                                                        foreground: theme
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                        onTap:
                                                            onOpenHistoryStats,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            StreamBuilder<
                                              List<ScheduledPayment>
                                            >(
                                              stream: transactionsRepository
                                                  .watchDueScheduledPayments(),
                                              builder: (context, dueSnapshot) {
                                                final due =
                                                    dueSnapshot.data ??
                                                    const <ScheduledPayment>[];
                                                if (due.isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: HitoSpacing.md,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Registros pendientes',
                                                        style: theme
                                                            .textTheme
                                                            .headlineMedium,
                                                      ),
                                                      const SizedBox(
                                                        height: HitoSpacing.sm,
                                                      ),
                                                      for (
                                                        var i = 0;
                                                        i < due.length;
                                                        i++
                                                      ) ...[
                                                        StaggeredFadeIn(
                                                          index: i,
                                                          child: _DuePaymentCard(
                                                            payment: due[i],
                                                            transactionsRepository:
                                                                transactionsRepository,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height:
                                                              HitoSpacing.sm,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(
                                              height: HitoSpacing.md,
                                            ),
                                            StreamBuilder<
                                              List<MoneyTransaction>
                                            >(
                                              stream: transactionsRepository
                                                  .watchTransactions(limit: 20),
                                              builder: (context, txSnapshot) {
                                                final allTx =
                                                    txSnapshot.data ??
                                                    const <MoneyTransaction>[];
                                                return StreamBuilder<
                                                  List<ScheduledPayment>
                                                >(
                                                  stream: transactionsRepository
                                                      .watchScheduledPayments(),
                                                  builder: (context, schedSnapshot) {
                                                    final scheduled =
                                                        schedSnapshot.data ??
                                                        const <
                                                          ScheduledPayment
                                                        >[];
                                                    final recent =
                                                        _buildRecentEntries(
                                                          allTx,
                                                          scheduled,
                                                        );
                                                    return _RecentEntriesSection(
                                                      recent: recent,
                                                      onViewHistory:
                                                          onViewHistory,
                                                      transactionsRepository:
                                                          transactionsRepository,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FeaturedGoalCard extends StatelessWidget {
  const _FeaturedGoalCard({required this.goal, required this.onPrimaryAction});

  final Goal? goal;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = this.goal;

    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: HitoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal?.title ?? 'Sin meta activa',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(goal?.savedAmount ?? 0),
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(
                      goal == null
                          ? 'Retomá tu hábito'
                          : 'Meta ${formatCurrency(goal.targetAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
                    value: goal?.progress ?? 0,
                    minHeight: 8,
                    backgroundColor: pageColor(theme),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Text(
                '%${(((goal?.progress ?? 0)) * 100).round()}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimaryAction,
              child: Text(goal == null ? 'Definir meta' : 'Ver detalles'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une transacciones reales y registros programados en una sola lista
/// para "Registros recientes" — un programado ya aceptado nunca se
/// muestra junto a la transacción que generó (sería la misma cosa
/// vista dos veces), así que la transacción vinculada se descarta acá.
class _HomeEntry {
  _HomeEntry.transaction(MoneyTransaction t)
    : transaction = t,
      scheduled = null,
      date = t.date;

  _HomeEntry.scheduled(ScheduledPayment p)
    : transaction = null,
      scheduled = p,
      date = p.effectiveDate;

  final MoneyTransaction? transaction;
  final ScheduledPayment? scheduled;
  final DateTime date;
}

List<_HomeEntry> _buildRecentEntries(
  List<MoneyTransaction> transactions,
  List<ScheduledPayment> scheduled,
) {
  final entries = <_HomeEntry>[
    for (final t in transactions)
      if (t.scheduledPaymentId == null) _HomeEntry.transaction(t),
    // Solo los ya realizados — los pendientes/vencidos ya tienen su
    // propia sección ("Registros pendientes") arriba.
    for (final p in scheduled)
      if (!p.isActive) _HomeEntry.scheduled(p),
  ];
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries.take(5).toList();
}

class _RecentEntriesSection extends StatelessWidget {
  const _RecentEntriesSection({
    required this.recent,
    required this.onViewHistory,
    required this.transactionsRepository,
  });

  final List<_HomeEntry> recent;
  final VoidCallback onViewHistory;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Registros recientes', style: theme.textTheme.headlineMedium),
            TextButton(
              onPressed: recent.isEmpty ? null : onViewHistory,
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: HitoSpacing.sm),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(HitoSpacing.lg),
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
              boxShadow: cardShadow(),
            ),
            alignment: Alignment.center,
            child: Text(
              'No registraste ingresos ni gastos últimamente. Empezá hoy.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                StaggeredFadeIn(
                  index: i,
                  child: recent[i].transaction != null
                      ? _TransactionRow(
                          transaction: recent[i].transaction!,
                          transactionsRepository: transactionsRepository,
                        )
                      : _ScheduledRecentRow(
                          payment: recent[i].scheduled!,
                          transactionsRepository: transactionsRepository,
                        ),
                ),
                const SizedBox(height: HitoSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

/// Card de un registro de ingreso/gasto: ícono de la categoría, nombre
/// de la categoría, fecha/hora como supporting text, y el monto en
/// verde (ingreso) o rojo (gasto) como tailing text.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.transactionsRepository,
  });

  final MoneyTransaction transaction;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final category = findCategory(transaction.categoryId);
    final amountColor = isIncome
        ? (isDark ? HitoColors.successDark : HitoColors.successLight)
        : theme.colorScheme.error;
    final sign = isIncome ? '+' : '-';
    final note = transaction.note.trim();

    return InkWell(
      onTap: () => openTransactionDetailSheet(
        context,
        transactionsRepository: transactionsRepository,
        transaction: transaction,
      ),
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HitoSpacing.md,
          vertical: HitoSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
          boxShadow: cardShadow(),
        ),
        child: Row(
          children: [
            TransactionIconAvatar(
              icon: category?.icon ?? Icons.category_outlined,
              background: isIncome
                  ? theme.colorScheme.tertiaryContainer
                  : theme.colorScheme.secondaryContainer,
              iconColor: isIncome
                  ? theme.colorScheme.onTertiaryContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.categoryLabel,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    formatMovementTimestamp(transaction.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sign${formatCurrency(transaction.amount.abs())}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de un registro programado ya "Realizado" — mismo look que su
/// equivalente en Historial (ícono de check, label "Realizado" +
/// horario), nunca la del ingreso/gasto normal.
class _ScheduledRecentRow extends StatelessWidget {
  const _ScheduledRecentRow({
    required this.payment,
    required this.transactionsRepository,
  });

  final ScheduledPayment payment;
  final TransactionsRepository transactionsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = payment.type == TransactionType.income;
    final isDark = theme.brightness == Brightness.dark;
    final amountColor = isIncome
        ? (isDark ? HitoColors.successDark : HitoColors.successLight)
        : theme.colorScheme.error;
    final sign = isIncome ? '+' : '-';

    return InkWell(
      onTap: () => openScheduledDetailSheet(
        context,
        transactionsRepository: transactionsRepository,
        payment: payment,
      ),
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
          boxShadow: cardShadow(),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: recessedColor(theme),
              child: Icon(
                Icons.check,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.name, style: theme.textTheme.bodyLarge),
                  Text(
                    'Realizado · ${formatMovementTimestamp(payment.effectiveDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sign${formatCurrency(payment.amount)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de acción para un registro planificado vencido — "Aceptar" crea
/// la transacción real ahora; "Reprogramar" solo mueve la fecha, sin
/// registrar nada todavía.
class _DuePaymentCard extends StatefulWidget {
  const _DuePaymentCard({
    required this.payment,
    required this.transactionsRepository,
  });

  final ScheduledPayment payment;
  final TransactionsRepository transactionsRepository;

  @override
  State<_DuePaymentCard> createState() => _DuePaymentCardState();
}

class _DuePaymentCardState extends State<_DuePaymentCard> {
  bool _busy = false;
  bool _accepted = false;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      // Tacha la card entera antes de registrar nada — el usuario
      // tiene que llegar a VER el tachado o el alivio se pierde, así
      // que la escritura real espera a que termine de mostrarse.
      _accepted = true;
    });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await Future.delayed(
      reduceMotion
          ? HitoMotion.scheduledHoldConfirmReduced
          : HitoMotion.scheduledHoldConfirm,
    );
    if (!mounted) return;
    try {
      await widget.transactionsRepository.acceptScheduledPayment(
        widget.payment,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Registrado');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await widget.transactionsRepository.rescheduleScheduledPayment(
        widget.payment.id,
        picked,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Reprogramado para ${formatGoalDate(picked)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = widget.payment;
    final sign = payment.type == TransactionType.income ? '+' : '-';

    return CardStrikeThrough(
      trigger: _accepted,
      child: Container(
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        payment.categoryLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$sign${formatCurrency(payment.amount)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HitoSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _reschedule,
                    child: const Text('Reprogramar'),
                  ),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _accept,
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Campana de notificaciones con indicador de "no leídas" — un punto
/// visible si hay algún ítem real más nuevo que la última vez que el
/// usuario marcó todo como leído (persistido localmente).
class _NotificationsBell extends StatefulWidget {
  const _NotificationsBell({
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;

  @override
  State<_NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<_NotificationsBell> {
  @override
  void initState() {
    super.initState();
    NotificationsReadState.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotificationItemsBuilder(
      goalsRepository: widget.goalsRepository,
      transactionsRepository: widget.transactionsRepository,
      settingsRepository: widget.settingsRepository,
      builder: (context, items) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: NotificationsReadState.instance.lastReadAt,
          builder: (context, lastReadAt, _) {
            final hasUnread = items.any(
              (item) =>
                  lastReadAt == null || item.timestamp.isAfter(lastReadAt),
            );
            return IconButton(
              tooltip: hasUnread
                  ? 'Notificaciones (hay nuevas)'
                  : 'Notificaciones',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    goalsRepository: widget.goalsRepository,
                    transactionsRepository: widget.transactionsRepository,
                    settingsRepository: widget.settingsRepository,
                  ),
                ),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.onPrimary,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.error,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
