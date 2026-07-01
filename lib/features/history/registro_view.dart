import 'package:flutter/material.dart';

import '../../data/movement.dart';
import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import 'scheduled_detail_sheet.dart';
import 'transaction_detail_sheet.dart';
import 'widgets/history_filter_sheet.dart';

class _Entry {
  _Entry.transaction(MoneyTransaction t)
      : transaction = t,
        scheduled = null,
        date = t.date;

  _Entry.scheduled(ScheduledPayment p)
      : transaction = null,
        scheduled = p,
        date = p.effectiveDate;

  final MoneyTransaction? transaction;
  final ScheduledPayment? scheduled;
  final DateTime date;

  String get name => transaction?.categoryLabel ?? scheduled?.name ?? '';
  String get note => transaction?.note ?? scheduled?.note ?? '';

  IconData? get categoryIcon {
    final id = transaction?.categoryId ?? scheduled?.categoryId;
    if (id == null) return null;
    return findCategory(id)?.icon;
  }

  double get signedAmount {
    if (transaction != null) return transaction!.signedAmount;
    final p = scheduled!;
    return p.type == TransactionType.income ? p.amount : -p.amount;
  }
}

/// Vista "Registro": buscador (por categoría o por texto de la nota) +
/// filtro por tipo/periodo, y la lista agrupada por día.
class RegistroView extends StatefulWidget {
  const RegistroView({
    super.key,
    required this.transactionsRepository,
    required this.transactions,
    required this.scheduled,
    this.initialFilters = const HistoryFilters(),
  });

  final TransactionsRepository transactionsRepository;
  final List<MoneyTransaction> transactions;
  final List<ScheduledPayment> scheduled;
  final HistoryFilters initialFilters;

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _searchController = TextEditingController();
  late HistoryFilters _filters = widget.initialFilters;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showHistoryFilterSheet(context, current: _filters);
    if (result != null) setState(() => _filters = result);
  }

  bool _inRange(DateTime date) {
    final range = _filters.range;
    if (range == null) return true;
    final (start, end) = range;
    return !date.isBefore(start) && date.isBefore(end);
  }

  String _dayHeaderFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'HOY';
    if (day == today.subtract(const Duration(days: 1))) return 'AYER';
    if (today.difference(day).inDays < 7) return 'ESTA SEMANA';
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _filters.type;
    final query = _searchController.text.trim().toLowerCase();

    final entries = <_Entry>[];
    if (type != HistoryTypeFilter.scheduled) {
      for (final t in widget.transactions) {
        if (type == HistoryTypeFilter.income && t.type != TransactionType.income) continue;
        if (type == HistoryTypeFilter.expense && t.type != TransactionType.expense) continue;
        if (!_inRange(t.date)) continue;
        // La transacción que generó un registro programado al
        // aceptarse no se muestra por separado — ese movimiento sigue
        // representado por su card de programado (que pasa a
        // "Realizado"), nunca por las dos a la vez.
        if (t.scheduledPaymentId != null) continue;
        entries.add(_Entry.transaction(t));
      }
    }
    if (type == HistoryTypeFilter.all || type == HistoryTypeFilter.scheduled) {
      for (final p in widget.scheduled) {
        if (!_inRange(p.effectiveDate)) continue;
        // Un programado se ve siempre como "Programados" — aceptado o
        // no — nunca se reclasifica como ingreso/gasto suelto.
        entries.add(_Entry.scheduled(p));
      }
    }
    if (query.isNotEmpty) {
      entries.retainWhere(
        (e) => e.name.toLowerCase().contains(query) || e.note.toLowerCase().contains(query),
      );
    }
    entries.sort((a, b) => b.date.compareTo(a.date));

    final grouped = <String, List<_Entry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(_dayHeaderFor(entry.date), () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(HitoSpacing.md, HitoSpacing.lg, HitoSpacing.md, HitoSpacing.xxl),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por categoría o nota...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: recessedColor(theme),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HitoRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: HitoSpacing.md - 2),
                ),
              ),
            ),
            const SizedBox(width: HitoSpacing.sm),
            Badge(
              label: Text('${_filters.activeCount}'),
              isLabelVisible: _filters.isActive,
              child: IconButton.filled(
                tooltip: 'Filtrar registros',
                style: IconButton.styleFrom(
                  backgroundColor: _filters.isActive
                      ? theme.colorScheme.primary
                      : recessedColor(theme),
                  foregroundColor: _filters.isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: _openFilters,
                icon: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        const SizedBox(height: HitoSpacing.lg),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: HitoSpacing.xxl),
            child: Center(
              child: Text(
                'No hay registros para este filtro.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final group in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: HitoSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.key,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    formatCurrency(group.value.fold<double>(0, (sum, e) => sum + e.signedAmount)),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            for (final entry in group.value) ...[
              _RecordCard(
                entry: entry,
                onTap: () => entry.transaction != null
                    ? openTransactionDetailSheet(
                        context,
                        transactionsRepository: widget.transactionsRepository,
                        transaction: entry.transaction!,
                      )
                    : openScheduledDetailSheet(
                        context,
                        transactionsRepository: widget.transactionsRepository,
                        payment: entry.scheduled!,
                      ),
              ),
              const SizedBox(height: HitoSpacing.sm),
            ],
            const SizedBox(height: HitoSpacing.xs),
          ],
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.entry, required this.onTap});

  final _Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = entry.signedAmount >= 0;
    final isScheduled = entry.scheduled != null;
    final amountColor = isIncome
        ? (isDark ? HitoColors.successDark : HitoColors.successLight)
        : theme.colorScheme.error;

    final time = formatTime24h(entry.transaction?.date ?? entry.scheduled!.effectiveDate);
    final note = entry.note.trim();
    // Un programado ya aceptado (isActive == false) generó su
    // transacción real — acá se muestra como "Realizado", nunca como
    // "Programado"/"Vencido" otra vez.
    final scheduledStatus = isScheduled
        ? (!entry.scheduled!.isActive
            ? 'Realizado'
            : (entry.scheduled!.isDue ? 'Vencido' : 'Programado'))
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.sm + 4),
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.md),
          boxShadow: cardShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isScheduled
                    ? recessedColor(theme)
                    : (isIncome ? theme.colorScheme.tertiaryContainer : theme.colorScheme.secondaryContainer),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isScheduled
                    ? (entry.scheduled!.isActive ? Icons.schedule_outlined : Icons.check)
                    : (entry.categoryIcon ?? Icons.category_outlined),
                size: 18,
                color: isScheduled
                    ? theme.colorScheme.onSurfaceVariant
                    : (isIncome ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      if (isScheduled) ...[
                        Text(
                          scheduledStatus!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheduledStatus == 'Vencido'
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Programado/Vencido son una fecha límite, no un
                        // horario real todavía — el horario solo existe
                        // una vez que el registro se acepta.
                        if (scheduledStatus == 'Realizado')
                          Text(
                            ' · $time',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ] else if (note.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          ' · ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (!isScheduled)
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: HitoSpacing.sm),
            Text(
              '${isIncome ? '+' : '-'}${formatCurrency(entry.signedAmount.abs())}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
