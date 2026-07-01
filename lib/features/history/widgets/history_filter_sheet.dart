import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

enum HistoryTypeFilter { all, income, expense, scheduled }

extension HistoryTypeFilterLabel on HistoryTypeFilter {
  String get label => switch (this) {
        HistoryTypeFilter.all => 'Todos',
        HistoryTypeFilter.income => 'Ingresos',
        HistoryTypeFilter.expense => 'Gastos',
        HistoryTypeFilter.scheduled => 'Programados',
      };
}

enum HistoryPeriod { today, yesterday, last7Days, last30Days, custom }

extension HistoryPeriodLabel on HistoryPeriod {
  String get label => switch (this) {
        HistoryPeriod.today => 'Hoy',
        HistoryPeriod.yesterday => 'Ayer',
        HistoryPeriod.last7Days => 'Última semana',
        HistoryPeriod.last30Days => 'Último mes',
        HistoryPeriod.custom => 'Periodo específico',
      };
}

class HistoryFilters {
  const HistoryFilters({
    this.type = HistoryTypeFilter.all,
    this.period,
    this.customStart,
    this.customEnd,
  });

  final HistoryTypeFilter type;
  final HistoryPeriod? period;
  final DateTime? customStart;
  final DateTime? customEnd;

  int get activeCount => (type != HistoryTypeFilter.all ? 1 : 0) + (period != null ? 1 : 0);

  bool get isActive => activeCount > 0;

  (DateTime, DateTime)? get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case null:
        return null;
      case HistoryPeriod.today:
        return (today, today.add(const Duration(days: 1)));
      case HistoryPeriod.yesterday:
        return (today.subtract(const Duration(days: 1)), today);
      case HistoryPeriod.last7Days:
        return (today.subtract(const Duration(days: 7)), now);
      case HistoryPeriod.last30Days:
        return (today.subtract(const Duration(days: 30)), now);
      case HistoryPeriod.custom:
        if (customStart == null || customEnd == null) return null;
        return (customStart!, customEnd!.add(const Duration(days: 1)));
    }
  }
}

/// Sheet de filtro completo (tipo + periodo). Pasar [showTypeFilter] en
/// `false` para un sheet solo de periodo (usado en Estadística, donde el
/// tipo ya se elige con el toggle Gastos/Ingresos).
Future<HistoryFilters?> showHistoryFilterSheet(
  BuildContext context, {
  required HistoryFilters current,
  bool showTypeFilter = true,
}) {
  return showModalBottomSheet<HistoryFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _HistoryFilterSheet(initial: current, showTypeFilter: showTypeFilter),
  );
}

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({required this.initial, required this.showTypeFilter});

  final HistoryFilters initial;
  final bool showTypeFilter;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistoryTypeFilter _type;
  HistoryPeriod? _period;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _period = widget.initial.period;
    _customStart = widget.initial.customStart;
    _customEnd = widget.initial.customEnd;
  }

  void _clear() {
    setState(() {
      _type = HistoryTypeFilter.all;
      _period = null;
      _customStart = null;
      _customEnd = null;
    });
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _customStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? DateTime.now(),
      firstDate: _customStart ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _customEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShow = _period != HistoryPeriod.custom || (_customStart != null && _customEnd != null);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              Text('Filtrar registros', style: theme.textTheme.headlineMedium),
              const SizedBox(height: HitoSpacing.lg),
              if (widget.showTypeFilter) ...[
                _sectionLabel(theme, 'Tipo'),
                const SizedBox(height: HitoSpacing.sm),
                Wrap(
                  spacing: HitoSpacing.sm,
                  runSpacing: HitoSpacing.sm,
                  children: [
                    for (final type in HistoryTypeFilter.values)
                      ChoiceChip(
                        label: Text(type.label),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                      ),
                  ],
                ),
                const SizedBox(height: HitoSpacing.lg),
              ],
              _sectionLabel(theme, 'Periodo'),
              const SizedBox(height: HitoSpacing.sm),
              Wrap(
                spacing: HitoSpacing.sm,
                runSpacing: HitoSpacing.sm,
                children: [
                  for (final period in HistoryPeriod.values)
                    ChoiceChip(
                      label: Text(period.label),
                      selected: _period == period,
                      onSelected: (_) => setState(() => _period = _period == period ? null : period),
                    ),
                ],
              ),
              if (_period == HistoryPeriod.custom) ...[
                const SizedBox(height: HitoSpacing.md),
                Row(
                  children: [
                    Expanded(child: _DateField(label: 'Desde', date: _customStart, onTap: _pickStart)),
                    const SizedBox(width: HitoSpacing.sm),
                    Expanded(child: _DateField(label: 'Hasta', date: _customEnd, onTap: _pickEnd)),
                  ],
                ),
              ],
              const SizedBox(height: HitoSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _clear, child: const Text('Limpiar')),
                  ),
                  const SizedBox(width: HitoSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: canShow
                          ? () => Navigator.of(context).pop(
                                HistoryFilters(
                                  type: widget.showTypeFilter ? _type : HistoryTypeFilter.all,
                                  period: _period,
                                  customStart: _customStart,
                                  customEnd: _customEnd,
                                ),
                              )
                          : null,
                      child: const Text('Mostrar resultados'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
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
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(HitoRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              date == null ? 'Elegir fecha' : '${date!.day}/${date!.month}/${date!.year}',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
