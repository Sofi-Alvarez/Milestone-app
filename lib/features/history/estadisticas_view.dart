import 'package:flutter/material.dart';

import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_stat_card.dart';
import '../../widgets/transaction_icon_avatar.dart';
import '../home/models/home_models.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/history_filter_sheet.dart';
import 'widgets/weekly_flow_chart.dart';

/// Vista "Estadística": saldo, flujo semanal, registros programados,
/// distribución por categoría (donut, filtrable por periodo) y detalle
/// por categoría. Colores y tipografía del sistema visual de la app.
class EstadisticasView extends StatefulWidget {
  const EstadisticasView({
    super.key,
    required this.transactions,
    required this.scheduled,
    required this.totalIncome,
    required this.totalExpense,
    required this.onViewAllScheduled,
  });

  final List<MoneyTransaction> transactions;
  final List<ScheduledPayment> scheduled;
  final double totalIncome;
  final double totalExpense;
  final VoidCallback onViewAllScheduled;

  @override
  State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView> {
  TransactionType _distributionType = TransactionType.expense;
  HistoryPeriod? _period;
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _inPeriod(DateTime date) {
    if (_period == null) return true;
    final filters = HistoryFilters(
      period: _period,
      customStart: _customStart,
      customEnd: _customEnd,
    );
    final range = filters.range;
    if (range == null) return true;
    final (start, end) = range;
    return !date.isBefore(start) && date.isBefore(end);
  }

  Future<void> _openPeriodFilter() async {
    final result = await showHistoryFilterSheet(
      context,
      current: HistoryFilters(
        period: _period,
        customStart: _customStart,
        customEnd: _customEnd,
      ),
      showTypeFilter: false,
    );
    if (result != null) {
      setState(() {
        _period = result.period;
        _customStart = result.customStart;
        _customEnd = result.customEnd;
      });
    }
  }

  List<FlowBucket> _buildWeekBuckets() {
    final now = DateTime.now();
    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return List.generate(7, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      final income = widget.transactions
          .where(
            (t) =>
                t.type == TransactionType.income &&
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day,
          )
          .fold<double>(0, (sum, t) => sum + t.amount);
      final expense = widget.transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day,
          )
          .fold<double>(0, (sum, t) => sum + t.amount);
      return FlowBucket(
        label: dayLabels[day.weekday - 1],
        income: income,
        expense: expense,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryPalette = [
      (theme.colorScheme.primary, theme.colorScheme.primaryContainer),
      (theme.colorScheme.tertiary, theme.colorScheme.tertiaryContainer),
      (theme.colorScheme.secondary, theme.colorScheme.secondaryContainer),
      (theme.colorScheme.error, theme.colorScheme.errorContainer),
      (theme.colorScheme.outline, theme.colorScheme.surfaceContainerHighest),
    ];

    final scheduledTotal = widget.scheduled.length;
    final scheduledDone = widget.scheduled.where((p) => !p.isActive).length;
    final scheduledPending = widget.scheduled
        .where((p) => p.isActive && !p.isDue)
        .length;

    final periodFiltered = widget.transactions
        .where((t) => _inPeriod(t.date))
        .toList();
    final filtered = periodFiltered
        .where((t) => t.type == _distributionType)
        .toList();
    final byCategory = <String, double>{};
    for (final t in filtered) {
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = filtered.fold<double>(0, (sum, t) => sum + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        HitoSpacing.md,
        HitoSpacing.lg,
        HitoSpacing.md,
        HitoSpacing.xxl,
      ),
      children: [
        _BalanceCard(
          balance: widget.totalIncome - widget.totalExpense,
          totalIncome: widget.totalIncome,
          totalExpense: widget.totalExpense,
        ),
        const SizedBox(height: HitoSpacing.lg),
        WeeklyFlowChart(buckets: _buildWeekBuckets()),
        const SizedBox(height: HitoSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registros programados',
              style: theme.textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: widget.onViewAllScheduled,
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: HitoSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconStatCard(
                width: 124,
                icon: Icons.event_repeat_outlined,
                iconColor: theme.colorScheme.primary,
                iconBackground: theme.colorScheme.primaryContainer,
                value: '$scheduledTotal',
                label: 'Programado',
              ),
              const SizedBox(width: HitoSpacing.md),
              IconStatCard(
                width: 124,
                icon: Icons.check,
                iconColor: HitoColors.successLight,
                iconBackground: HitoColors.successContainerLight,
                value: '$scheduledDone',
                label: 'Realizado',
              ),
              const SizedBox(width: HitoSpacing.md),
              IconStatCard(
                width: 124,
                icon: Icons.access_time,
                iconColor: HitoColors.warningLight,
                iconBackground: HitoColors.warningContainerLight,
                value: '$scheduledPending',
                label: 'Pendiente',
              ),
            ],
          ),
        ),
        const SizedBox(height: HitoSpacing.lg),
        Text('¿A dónde va mi dinero?', style: theme.textTheme.headlineMedium),
        const SizedBox(height: HitoSpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 180,
              child: HitoToggle<TransactionType>(
                options: const [
                  (TransactionType.expense, 'Gastos'),
                  (TransactionType.income, 'Ingresos'),
                ],
                selected: _distributionType,
                onChanged: (t) => setState(() => _distributionType = t),
              ),
            ),
            const Spacer(),
            Badge(
              label: Text('${_period != null ? 1 : 0}'),
              isLabelVisible: _period != null,
              child: IconButton.filled(
                tooltip: 'Filtrar por periodo',
                style: IconButton.styleFrom(
                  backgroundColor: _period != null
                      ? theme.colorScheme.primary
                      : recessedColor(theme),
                  foregroundColor: _period != null
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _openPeriodFilter,
                icon: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        const SizedBox(height: HitoSpacing.md),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.xl),
            decoration: BoxDecoration(
              color: cardColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.hero),
              boxShadow: cardShadow(),
            ),
            alignment: Alignment.center,
            child: Text(
              'Sin datos para este periodo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          CategoryDonutChart(
            centerLabel: _distributionType == TransactionType.expense
                ? 'Total gastado'
                : 'Total recibido',
            slices: [
              for (var i = 0; i < entries.length; i++)
                CategorySlice(
                  label: findCategory(entries[i].key)?.label ?? 'Otros',
                  amount: entries[i].value,
                  color: categoryPalette[i % categoryPalette.length].$1,
                ),
            ],
          ),
        const SizedBox(height: HitoSpacing.lg),
        Text('Detalle por categoría', style: theme.textTheme.headlineMedium),
        const SizedBox(height: HitoSpacing.md),
        for (var i = 0; i < entries.length; i++) ...[
          _CategoryRow(
            category: findCategory(entries[i].key),
            amount: entries[i].value,
            percent: total == 0 ? 0 : entries[i].value / total,
            color: categoryPalette[i % categoryPalette.length].$1,
            colorLight: categoryPalette[i % categoryPalette.length].$2,
          ),
          const SizedBox(height: HitoSpacing.sm),
        ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(HitoRadius.hero),
        boxShadow: heroShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DINERO DISPONIBLE',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: HitoSpacing.xs),
          Text(
            formatCurrency(balance),
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: HitoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_downward,
                  label: 'Ingresos',
                  value: totalIncome,
                ),
              ),
              const SizedBox(width: HitoSpacing.md),
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_upward,
                  label: 'Gastos',
                  value: totalExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final double value;

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
          Row(
            children: [
              Icon(icon, size: 12, color: onPrimary.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Text(
            formatCurrency(value),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
    required this.colorLight,
  });

  final TransactionCategory? category;
  final double amount;
  final double percent;
  final Color color;
  final Color colorLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TransactionIconAvatar(
            icon: category?.icon ?? Icons.category_outlined,
            background: colorLight,
            iconColor: color,
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
                      category?.label ?? 'Otros',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatCurrency(amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HitoSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(HitoRadius.full),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: recessedColor(theme),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    Text(
                      '${(percent * 100).round()}%',
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
    );
  }
}
