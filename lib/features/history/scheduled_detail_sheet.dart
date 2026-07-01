import 'package:flutter/material.dart';

import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/card_strike_through.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../home/models/home_models.dart';
import '../register/category_picker_sheet.dart';
import '../register/schedule_payment_screen.dart';
import '../savings/widgets/goal_form_fields.dart';

/// Detalle de un registro programado — editar monto/categoría/próxima
/// fecha acá mismo, "Configuración avanzada" para frecuencia/
/// notificaciones/recurrencia, o Aceptar ahora / Reprogramar / eliminar.
Future<void> openScheduledDetailSheet(
  BuildContext context, {
  required TransactionsRepository transactionsRepository,
  required ScheduledPayment payment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScheduledDetailSheet(
      transactionsRepository: transactionsRepository,
      payment: payment,
    ),
  );
}

class _ScheduledDetailSheet extends StatefulWidget {
  const _ScheduledDetailSheet({required this.transactionsRepository, required this.payment});

  final TransactionsRepository transactionsRepository;
  final ScheduledPayment payment;

  @override
  State<_ScheduledDetailSheet> createState() => _ScheduledDetailSheetState();
}

class _ScheduledDetailSheetState extends State<_ScheduledDetailSheet> {
  bool _busy = false;
  // Refleja el estado real persistido, no solo lo que pasó en esta
  // sesión del sheet — si el registro ya fue aceptado antes, reabrirlo
  // debe mostrar directamente "Guardar cambios" sin "Aceptar ahora".
  late bool _accepted = !widget.payment.isActive;
  // Distinto de _accepted: solo se prende al tocar "Aceptar ahora" EN
  // esta sesión — dispara la animación de tachado. Si el registro ya
  // venía aceptado de antes, no hay nada que animar al reabrir.
  bool _justAccepted = false;
  bool _saving = false;

  late TransactionType _type = widget.payment.type;
  late TransactionCategory? _category = findCategory(widget.payment.categoryId);
  late final _amountController =
      TextEditingController(text: formatCurrency(widget.payment.amount).replaceAll('\$', ''));
  final _amountFocus = FocusNode();
  late DateTime _nextDueDate = widget.payment.nextDueDate;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double get _amount => parseAmountInput(_amountController.text);

  bool get _isDirty =>
      _type != widget.payment.type ||
      _category?.id != widget.payment.categoryId ||
      _amount != widget.payment.amount ||
      _nextDueDate != widget.payment.nextDueDate;

  bool get _canSave => _isDirty && _amount > 0 && _category != null;

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
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
      initialDate: _nextDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _saveChanges() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await widget.transactionsRepository.updateScheduledPaymentFields(
        widget.payment.id,
        type: _type,
        amount: _amount,
        categoryId: _category!.id,
        categoryLabel: _category!.label,
        nextDueDate: _nextDueDate,
      );
      if (!mounted) return;
      setState(() {
        _accepted = false;
        _justAccepted = false;
      });
      showAppSnackBar(context, 'Cambios guardados');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos guardar: $e', isError: true);
    }
  }

  Future<void> _openAdvancedConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchedulePaymentScreen(
          transactionsRepository: widget.transactionsRepository,
          existingPayment: widget.payment,
        ),
      ),
    );
    // Los datos pueden haber cambiado en la config avanzada — cerramos
    // el detalle en vez de mostrar una copia desactualizada.
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      // Igual que en el Home: el usuario tiene que ver el tachado
      // completo antes de que pase cualquier otra cosa.
      _accepted = true;
      _justAccepted = true;
    });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await Future.delayed(
      reduceMotion ? const Duration(milliseconds: 500) : const Duration(milliseconds: 2400),
    );
    if (!mounted) return;
    try {
      await widget.transactionsRepository.acceptScheduledPayment(widget.payment);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDialog(
      context,
      title: '¿Eliminar registro programado?',
      body: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    await widget.transactionsRepository.deleteScheduledPayment(widget.payment.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = widget.payment;
    final sign = _type == TransactionType.income ? '+' : '-';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor(theme),
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
                CardStrikeThrough(
                  trigger: _justAccepted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _category?.icon ?? Icons.schedule_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: HitoSpacing.sm),
                          Expanded(
                            child: Text(payment.name, style: theme.textTheme.headlineMedium),
                          ),
                          IconButton(
                            tooltip: 'Eliminar registro programado',
                            onPressed: _busy ? null : _delete,
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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
                        onChanged: _busy ? (_) {} : _onTypeChanged,
                      ),
                      const SizedBox(height: HitoSpacing.md),
                      AnimatedBuilder(
                        animation: _amountFocus,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.sm),
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
                              sign,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocus,
                                textAlign: TextAlign.left,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              onPressed: _busy ? null : () => _amountFocus.requestFocus(),
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
                        onTap: _busy ? null : _pickCategory,
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
                              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: HitoSpacing.sm),
                      InkWell(
                        onTap: _busy ? null : _pickDate,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.isDue ? 'Vencido' : 'Próxima fecha',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: payment.isDue
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      formatGoalDate(_nextDueDate),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
                    ],
                  ),
                ),
                const SizedBox(height: HitoSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _openAdvancedConfig,
                    child: const Text('Configuración avanzada'),
                  ),
                ),
                const SizedBox(height: HitoSpacing.md),
                Row(
                  children: [
                    Expanded(
                      // Una vez aceptado, este es el único botón que queda
                      // — pasa a ocupar todo el ancho y a ser primario, ya
                      // no compite visualmente con "Aceptar ahora".
                      child: _accepted
                          ? FilledButton(
                              onPressed: (_canSave && !_saving) ? _saveChanges : null,
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Guardar cambios'),
                            )
                          : OutlinedButton(
                              onPressed: (_canSave && !_saving) ? _saveChanges : null,
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Guardar cambios'),
                            ),
                    ),
                    if (!_accepted) ...[
                    const SizedBox(width: HitoSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _accept,
                        child: const Text('Aceptar ahora'),
                      ),
                    ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
