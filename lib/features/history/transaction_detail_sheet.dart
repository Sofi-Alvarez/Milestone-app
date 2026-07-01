import 'package:flutter/material.dart';

import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../home/models/home_models.dart';
import '../register/category_picker_sheet.dart';
import '../savings/widgets/goal_form_fields.dart';

/// Detalle de un registro real: editar tipo/categoría/monto/fecha/nota,
/// o eliminarlo.
Future<void> openTransactionDetailSheet(
  BuildContext context, {
  required TransactionsRepository transactionsRepository,
  required MoneyTransaction transaction,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (context) => _TransactionDetailSheet(
      transactionsRepository: transactionsRepository,
      transaction: transaction,
    ),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({
    required this.transactionsRepository,
    required this.transaction,
  });

  final TransactionsRepository transactionsRepository;
  final MoneyTransaction transaction;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  late TransactionType _type;
  late TransactionCategory? _category;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _type = t.type;
    _category = findCategory(t.categoryId);
    _amountController = TextEditingController(
      text: formatCurrency(t.amount).replaceAll('\$', ''),
    );
    _noteController = TextEditingController(text: t.note);
    _date = t.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double get _amount => parseAmountInput(_amountController.text);

  bool get _isValid => _amount > 0 && _category != null;

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      // La categoría no es válida para el otro tipo — se reinicia.
      _category = null;
    });
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(context, type: _type);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    try {
      await widget.transactionsRepository.updateTransaction(
        widget.transaction.id,
        type: _type,
        amount: _amount,
        categoryId: _category!.id,
        categoryLabel: _category!.label,
        date: _date,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDialog(
      context,
      title: '¿Eliminar registro?',
      body: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    await widget.transactionsRepository.deleteTransaction(
      widget.transaction.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Empuja el sheet hacia arriba cuando aparece el teclado, para
      // que el campo que se está editando (ej. la nota) nunca quede
      // tapado.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor(theme),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          HitoSpacing.lg,
          HitoSpacing.sm,
          HitoSpacing.lg,
          HitoSpacing.lg,
        ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del registro',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar registro',
                      onPressed: _delete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HitoSpacing.md),
                HitoToggle<TransactionType>(
                  options: const [
                    (TransactionType.income, 'Ingreso'),
                    (TransactionType.expense, 'Gasto'),
                  ],
                  selected: _type,
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: HitoSpacing.md),
                AnimatedBuilder(
                  animation: _amountFocus,
                  builder: (context, child) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HitoSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                      border: Border.all(
                        color: _amountFocus.hasFocus
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: child,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _type == TransactionType.income ? '+' : '-',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocus,
                          textAlign: TextAlign.left,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [ThousandsInputFormatter()],
                          style: theme.textTheme.headlineMedium,
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixText: '\$ ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar monto',
                        onPressed: () => _amountFocus.requestFocus(),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HitoSpacing.sm),
                InkWell(
                  onTap: _pickCategory,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(HitoSpacing.md),
                    decoration: BoxDecoration(
                      color: recessedColor(theme),
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _category?.icon ?? Icons.category_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: HitoSpacing.sm),
                        Expanded(
                          child: Text(
                            _category?.label ?? 'Elegí una categoría',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HitoSpacing.sm),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(HitoSpacing.md),
                    decoration: BoxDecoration(
                      color: recessedColor(theme),
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatGoalDate(_date),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HitoSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HitoSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: recessedColor(theme),
                    borderRadius: BorderRadius.circular(HitoRadius.md),
                  ),
                  child: TextField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    decoration: const InputDecoration(
                      hintText: 'Nota (opcional)',
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: HitoSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_isValid && !_saving) ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
