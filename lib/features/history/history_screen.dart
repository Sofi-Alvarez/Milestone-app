import 'package:flutter/material.dart';

import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import 'estadisticas_view.dart';
import 'registro_view.dart';
import 'widgets/history_filter_sheet.dart';

enum HistoryInitialView { registro, estadistica }

typedef _HistoryView = HistoryInitialView;

/// Sección "Actividad" (Historial) — dos vistas alternadas por un
/// toggle superior, calcadas 1:1 del frame de Figma (node 606:9500):
/// Registro (buscador + lista agrupada por día) y Estadística (saldo,
/// flujo semanal, programados, distribución por categoría).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.transactionsRepository,
    this.initialView = HistoryInitialView.registro,
  });

  final TransactionsRepository transactionsRepository;
  final HistoryInitialView initialView;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late _HistoryView _view = widget.initialView;
  HistoryFilters _registroFilters = const HistoryFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = pageColor(theme);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Actividad', style: theme.textTheme.bodyLarge),
      ),
      body: StreamBuilder<List<MoneyTransaction>>(
        stream: widget.transactionsRepository.watchTransactions(limit: 500),
        builder: (context, txSnapshot) {
          final transactions = txSnapshot.data ?? const <MoneyTransaction>[];

          return StreamBuilder<List<ScheduledPayment>>(
            stream: widget.transactionsRepository.watchScheduledPayments(),
            builder: (context, scheduledSnapshot) {
              final scheduled = scheduledSnapshot.data ?? const <ScheduledPayment>[];

              final totalIncome = transactions
                  .where((t) => t.type == TransactionType.income)
                  .fold<double>(0, (sum, t) => sum + t.amount);
              final totalExpense = transactions
                  .where((t) => t.type == TransactionType.expense)
                  .fold<double>(0, (sum, t) => sum + t.amount);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      HitoSpacing.md,
                      0,
                      HitoSpacing.md,
                      HitoSpacing.md,
                    ),
                    child: HitoToggle<_HistoryView>(
                      options: const [
                        (_HistoryView.registro, 'Registro'),
                        (_HistoryView.estadistica, 'Estadística'),
                      ],
                      selected: _view,
                      onChanged: (v) => setState(() {
                        _view = v;
                        // Cambiar de vista limpia el filtro/búsqueda de
                        // Registro — evita que quede un filtro "invisible"
                        // aplicado cuando el usuario vuelve más tarde.
                        _registroFilters = const HistoryFilters();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _view == _HistoryView.registro
                        ? RegistroView(
                            key: ValueKey(_registroFilters),
                            transactionsRepository: widget.transactionsRepository,
                            transactions: transactions,
                            scheduled: scheduled,
                            initialFilters: _registroFilters,
                          )
                        : EstadisticasView(
                            transactions: transactions,
                            scheduled: scheduled,
                            totalIncome: totalIncome,
                            totalExpense: totalExpense,
                            onViewAllScheduled: () => setState(() {
                              _registroFilters = const HistoryFilters(
                                type: HistoryTypeFilter.scheduled,
                              );
                              _view = _HistoryView.registro;
                            }),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

