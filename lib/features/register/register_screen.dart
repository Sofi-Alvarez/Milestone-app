import 'package:flutter/material.dart';

import '../../data/transaction_category.dart';
import '../../data/transactions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../home/models/home_models.dart';
import '../savings/widgets/goal_form_fields.dart';
import 'category_picker_sheet.dart';
import 'schedule_payment_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.transactionsRepository,
    required this.onDone,
  });

  final TransactionsRepository transactionsRepository;

  /// Vuelve a Home — se llama al tocar la X del appbar o al terminar
  /// de registrar/programar con éxito.
  final VoidCallback onDone;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();

  TransactionCategory? _category;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _advancedExpanded = false;
  bool _saving = false;

  // Validación on-blur: el mensaje de error solo aparece después de que
  // el usuario interactuó con el campo, nunca antes.
  bool _amountTouched = false;
  bool _categoryTouched = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _amountFocus.addListener(() {
      if (!_amountFocus.hasFocus) setState(() => _amountTouched = true);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double get _amount => parseAmountInput(_amountController.text);

  bool get _isValid => _amount > 0 && _category != null;

  String? get _amountError => _amountTouched && _amount <= 0
      ? 'El monto tiene que ser mayor a \$0'
      : null;

  String? get _categoryError => _categoryTouched && _category == null
      ? 'Elegí una categoría para continuar'
      : null;

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      // La categoría no es válida para el otro tipo — se reinicia.
      _category = null;
    });
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(context, type: _type);
    setState(() {
      _categoryTouched = true;
      if (picked != null) _category = picked;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final combinedDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    try {
      await widget.transactionsRepository.createTransaction(
        type: _type,
        amount: _amount,
        categoryId: _category!.id,
        categoryLabel: _category!.label,
        date: combinedDate,
        note: _noteController.text.trim(),
      );
      // Si el gasto deja el saldo por debajo de cero, avisamos en vez del
      // mensaje normal — la app no inventa que todo está bien.
      final balance = await widget.transactionsRepository.watchBalance().first;
      if (!mounted) return;
      setState(() {
        _amountController.clear();
        _category = null;
        _noteController.clear();
        _date = DateTime.now();
        _time = TimeOfDay.now();
        _saving = false;
        _amountTouched = false;
        _categoryTouched = false;
      });
      if (balance < 0) {
        showAppSnackBar(
          context,
          'Tu dinero disponible está por debajo del mínimo.',
          isError: true,
        );
      } else {
        showAppSnackBar(
          context,
          _type == TransactionType.income
              ? 'Ingreso registrado'
              : 'Gasto registrado',
        );
      }
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos registrar: $e', isError: true);
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
          leading: IconButton(
            tooltip: 'Volver a Inicio',
            onPressed: widget.onDone,
            icon: const Icon(Icons.close),
          ),
          title: const Text('Registrar'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Programar registro',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SchedulePaymentScreen(
                    transactionsRepository: widget.transactionsRepository,
                    onSaved: widget.onDone,
                  ),
                ),
              ),
              icon: const Icon(Icons.schedule_outlined),
            ),
          ],
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
                HitoToggle<TransactionType>(
                  options: const [
                    (TransactionType.income, 'Ingreso'),
                    (TransactionType.expense, 'Gasto'),
                  ],
                  selected: _type,
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: HitoSpacing.xl),
                Center(
                  child: Text(
                    'MONTO TOTAL',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: HitoSpacing.xs),
                _AmountField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                ),
                if (_amountError != null) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Center(
                    child: Text(
                      _amountError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.xl),
                // Categoría: obligatoria para cualquier registro, por eso
                // va siempre visible, no dentro de "Configuración avanzada".
                Text(
                  'Categoría',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: HitoSpacing.xs),
                InkWell(
                  onTap: _pickCategory,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(HitoSpacing.md),
                    decoration: BoxDecoration(
                      color: recessedColor(theme),
                      border: _categoryError != null
                          ? Border.all(color: theme.colorScheme.error)
                          : null,
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _category?.icon ?? Icons.category_outlined,
                          size: 22,
                          color: _category != null
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                        const SizedBox(width: HitoSpacing.sm),
                        Expanded(
                          child: Text(
                            _category?.label ?? 'Elegí una categoría',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _category != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                            ),
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
                if (_categoryError != null) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    _categoryError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.lg),
                InkWell(
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                  onTap: () =>
                      setState(() => _advancedExpanded = !_advancedExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: HitoSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _advancedExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: HitoSpacing.xs),
                        Text(
                          'Configuración avanzada',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_advancedExpanded) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    'Si no las cambiás, se usa la fecha y hora de ahora. '
                    'La nota es opcional.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          label: 'Fecha',
                          value: formatGoalDate(_date),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: HitoSpacing.sm),
                      Expanded(
                        child: _PickerField(
                          label: 'Hora',
                          value: _time.format(context),
                          icon: Icons.access_time,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
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
                    child: EditableGoalField(
                      label: 'Nota (opcional)',
                      controller: _noteController,
                      focusNode: _noteFocus,
                      placeholder: 'Escribí una nota',
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ],
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
                  : const Text('Registrar'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monto grande centrado — mismo patrón de tap-to-edit que el resto de la
/// app (foco -> teclado numérico nativo -> vuelve a texto estático al
/// perder el foco), solo que centrado y más grande para esta pantalla.
class _AmountField extends StatefulWidget {
  const _AmountField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = widget.controller.text.isNotEmpty;

    return InkWell(
      onTap: () {
        setState(() => _editing = true);
        widget.focusNode.requestFocus();
      },
      child: Center(
        child: _editing
            ? TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [ThousandsInputFormatter()],
                onSubmitted: (_) => widget.focusNode.unfocus(),
                style: theme.textTheme.displayMedium,
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  prefixText: '\$ ',
                ),
              )
            : Text(
                hasValue
                    ? formatCurrency(
                        parseAmountInput(widget.controller.text),
                      ).replaceAll('\$', '\$ ')
                    : '\$ 0,00',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: hasValue
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                ),
              ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(HitoRadius.md),
      onTap: onTap,
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
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
