import 'package:flutter/material.dart';

import '../../data/transaction.dart';
import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../home/models/home_models.dart';
import '../savings/widgets/goal_form_fields.dart';
import 'category_picker_sheet.dart';

class SchedulePaymentScreen extends StatefulWidget {
  const SchedulePaymentScreen({
    super.key,
    required this.transactionsRepository,
    this.existingPayment,
    this.onSaved,
  });

  final TransactionsRepository transactionsRepository;

  /// Si viene seteado, la pantalla edita este registro programado en
  /// vez de crear uno nuevo — "Configuración avanzada" desde el
  /// detalle abre acá con todos los campos completos.
  final ScheduledPayment? existingPayment;

  /// Si viene seteado (solo al programar desde Registrar), se llama
  /// tras guardar con éxito en vez del pop normal — vuelve a Home.
  final VoidCallback? onSaved;

  @override
  State<SchedulePaymentScreen> createState() => _SchedulePaymentScreenState();
}

class _SchedulePaymentScreenState extends State<SchedulePaymentScreen> {
  late final _nameController =
      TextEditingController(text: widget.existingPayment?.name ?? '');
  final _nameFocus = FocusNode();
  late final _amountController = TextEditingController(
    text: widget.existingPayment == null
        ? ''
        : formatCurrency(widget.existingPayment!.amount).replaceAll('\$', ''),
  );
  final _amountFocus = FocusNode();
  late final _noteController =
      TextEditingController(text: widget.existingPayment?.note ?? '');
  final _noteFocus = FocusNode();

  late TransactionType _type = widget.existingPayment?.type ?? TransactionType.expense;
  late TransactionCategory? _category = widget.existingPayment == null
      ? null
      : findCategory(widget.existingPayment!.categoryId);
  late PaymentFrequency _frequency =
      widget.existingPayment?.frequency ?? PaymentFrequency.once;
  late DateTime _date =
      widget.existingPayment?.date ?? DateTime.now().add(const Duration(days: 1));
  late PaymentNotification _notification =
      widget.existingPayment?.notification ?? PaymentNotification.none;

  late RecurrenceUnit _recurrenceUnit =
      widget.existingPayment?.recurrenceUnit ?? RecurrenceUnit.monthly;
  late int _recurrenceInterval = widget.existingPayment?.recurrenceInterval ?? 1;
  late RecurrenceEndType _recurrenceEndType =
      widget.existingPayment?.recurrenceEndType ?? RecurrenceEndType.forever;
  late DateTime? _recurrenceEndDate = widget.existingPayment?.recurrenceEndDate;
  late int _recurrenceOccurrences = widget.existingPayment?.recurrenceOccurrences ?? 1;

  bool _saving = false;

  bool get _isEditing => widget.existingPayment != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameController, _amountController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double get _amount => parseAmountInput(_amountController.text);

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _amount > 0 && _category != null;

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(context, type: _type);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _date.add(const Duration(days: 30)),
      firstDate: _date,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _recurrenceEndDate = picked);
  }

  Future<void> _save() async {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final existing = widget.existingPayment;
    final payment = ScheduledPayment(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      categoryId: _category!.id,
      categoryLabel: _category!.label,
      amount: _amount,
      frequency: _frequency,
      date: _date,
      notification: _notification,
      recurrenceUnit: _frequency == PaymentFrequency.recurring ? _recurrenceUnit : null,
      recurrenceInterval:
          _frequency == PaymentFrequency.recurring ? _recurrenceInterval : null,
      recurrenceEndType:
          _frequency == PaymentFrequency.recurring ? _recurrenceEndType : null,
      recurrenceEndDate: _frequency == PaymentFrequency.recurring &&
              _recurrenceEndType == RecurrenceEndType.untilDate
          ? _recurrenceEndDate
          : null,
      recurrenceOccurrences: _frequency == PaymentFrequency.recurring &&
              _recurrenceEndType == RecurrenceEndType.occurrences
          ? _recurrenceOccurrences
          : null,
      note: _noteController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      // Si el usuario cambió la fecha en el formulario, eso reprograma
      // cuándo va a pedirse de nuevo.
      nextDueDate: _date,
      isActive: existing?.isActive ?? true,
    );
    try {
      if (existing != null) {
        await widget.transactionsRepository.updateScheduledPayment(existing.id, payment);
      } else {
        await widget.transactionsRepository.createScheduledPayment(payment);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        existing != null ? 'Registro planificado actualizado' : 'Registro planificado guardado',
      );
      // Solo al crear desde Registrar: vuelve a Home además de cerrar
      // esta pantalla — es el mismo CTA "Registrar" en otra forma.
      if (existing == null) widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos guardar: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: pageColor(theme),
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar registro programado' : 'Programar registro'),
          centerTitle: false,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              HitoSpacing.lg,
              HitoSpacing.md,
              HitoSpacing.lg,
              HitoSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aviso real: no se registra solo. Cuando llegue la fecha,
                // vas a ver una notificación y una card en el Home para
                // aceptarlo o reprogramarlo.
                Container(
                  padding: const EdgeInsets.all(HitoSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(HitoRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: HitoSpacing.sm),
                      Expanded(
                        child: Text(
                          'No se registra solo en la fecha. Vas a recibir una '
                          'notificación y una card en el Home para aceptarlo '
                          'o reprogramarlo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HitoSpacing.lg),
                SegmentedButton<TransactionType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TransactionType.income, label: Text('Ingreso')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Gasto')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => setState(() {
                    _type = selection.first;
                    _category = null;
                  }),
                ),
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Nombre',
                  controller: _nameController,
                  focusNode: _nameFocus,
                  placeholder: 'Sin nombre',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: HitoSpacing.md),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Categoría',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _category?.label ?? 'Elegí una categoría',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
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
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de dinero',
                  controller: _amountController,
                  focusNode: _amountFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: HitoSpacing.lg),
                Text('Frecuencia', style: theme.textTheme.headlineMedium),
                const SizedBox(height: HitoSpacing.sm),
                SegmentedButton<PaymentFrequency>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: PaymentFrequency.once, label: Text('Una vez')),
                    ButtonSegment(
                      value: PaymentFrequency.recurring,
                      label: Text('Pago recurrente'),
                    ),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (selection) =>
                      setState(() => _frequency = selection.first),
                ),
                const SizedBox(height: HitoSpacing.md),
                GoalDateField(date: _date, onTap: _pickDate),
                const SizedBox(height: HitoSpacing.md),
                _DropdownField<PaymentNotification>(
                  label: 'Notificaciones',
                  value: _notification,
                  items: const {
                    PaymentNotification.none: 'Ninguno',
                    PaymentNotification.onDueDate: 'En la fecha de vencimiento',
                    PaymentNotification.oneDayBefore: 'Un día antes',
                    PaymentNotification.threeDaysBefore: 'Tres días antes',
                    PaymentNotification.oneWeekBefore: 'Una semana antes',
                  },
                  onChanged: (v) => setState(() => _notification = v),
                ),
                if (_frequency == PaymentFrequency.recurring) ...[
                  const SizedBox(height: HitoSpacing.lg),
                  Text('Recurrencia', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: HitoSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField<RecurrenceUnit>(
                          label: 'Repetir',
                          value: _recurrenceUnit,
                          items: const {
                            RecurrenceUnit.daily: 'Diario',
                            RecurrenceUnit.weekly: 'Semanal',
                            RecurrenceUnit.monthly: 'Mensual',
                            RecurrenceUnit.yearly: 'Anual',
                          },
                          onChanged: (v) => setState(() => _recurrenceUnit = v),
                        ),
                      ),
                      const SizedBox(width: HitoSpacing.sm),
                      Expanded(
                        child: _StepperField(
                          label: 'Cada',
                          value: _recurrenceInterval,
                          onChanged: (v) => setState(() => _recurrenceInterval = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                  _DropdownField<RecurrenceEndType>(
                    label: 'Hasta',
                    value: _recurrenceEndType,
                    items: const {
                      RecurrenceEndType.forever: 'Siempre',
                      RecurrenceEndType.untilDate: 'Una fecha',
                      RecurrenceEndType.occurrences: 'Número de eventos',
                    },
                    onChanged: (v) => setState(() => _recurrenceEndType = v),
                  ),
                  if (_recurrenceEndType == RecurrenceEndType.untilDate) ...[
                    const SizedBox(height: HitoSpacing.sm),
                    GoalDateField(date: _recurrenceEndDate, onTap: _pickRecurrenceEndDate),
                  ],
                  if (_recurrenceEndType == RecurrenceEndType.occurrences) ...[
                    const SizedBox(height: HitoSpacing.sm),
                    _StepperField(
                      label: 'Cantidad de eventos',
                      value: _recurrenceOccurrences,
                      onChanged: (v) => setState(() => _recurrenceOccurrences = v),
                    ),
                  ],
                ],
                const SizedBox(height: HitoSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
                  decoration: BoxDecoration(
                    color: recessedColor(theme),
                    borderRadius: BorderRadius.circular(HitoRadius.md),
                  ),
                  child: EditableGoalField(
                    label: 'Nota',
                    controller: _noteController,
                    focusNode: _noteFocus,
                    placeholder: 'Escribí una nota',
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(height: HitoSpacing.xl),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            HitoSpacing.lg,
            HitoSpacing.sm,
            HitoSpacing.lg,
            HitoSpacing.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_isValid && !_saving) ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
      decoration: BoxDecoration(
        color: recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: HitoSpacing.sm),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            items: items.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.sm),
      decoration: BoxDecoration(
        color: recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: HitoSpacing.sm, left: HitoSpacing.sm),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Restar',
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, size: 18),
              ),
              Text('$value', style: theme.textTheme.bodyLarge),
              IconButton(
                tooltip: 'Sumar',
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
