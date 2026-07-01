import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/budget.dart';
import '../../data/budgets_repository.dart';
import '../../data/transaction_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../home/models/home_models.dart';
import '../register/category_picker_sheet.dart';
import 'widgets/goal_form_fields.dart';

/// Abre la creación de presupuesto, o — si viene [duplicateFrom] — la
/// misma pantalla precargada con esos datos ("Duplicar presupuesto
/// anterior").
void openCreateBudgetScreen(
  BuildContext context, {
  required BudgetsRepository repository,
  Budget? duplicateFrom,
  Budget? existingBudget,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateBudgetScreen(
        repository: repository,
        duplicateFrom: duplicateFrom,
        existingBudget: existingBudget,
      ),
    ),
  );
}

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({
    super.key,
    required this.repository,
    this.duplicateFrom,
    this.existingBudget,
  });

  final BudgetsRepository repository;

  /// Precarga el formulario con estos datos para crear uno nuevo
  /// ("Duplicar presupuesto anterior").
  final Budget? duplicateFrom;

  /// Si viene seteado, la pantalla edita este presupuesto en vez de
  /// crear uno nuevo ("Editar presupuesto").
  final Budget? existingBudget;

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

const _stepCount = 4;

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  Budget? get _source => widget.existingBudget ?? widget.duplicateFrom;
  bool get _isEditing => widget.existingBudget != null;

  int _step = 0;

  late final _nameController = TextEditingController(text: _source?.name ?? '');
  late final _limitController = TextEditingController(
    text: _source == null ? '' : formatCurrency(_source!.limitAmount).replaceAll('\$', ''),
  );
  late final _noteController = TextEditingController(text: _source?.note ?? '');

  late BudgetType _type = _source?.type ?? BudgetType.byCategory;
  late DateTime? _endDate = widget.existingBudget != null
      ? widget.existingBudget!.endDate
      : (widget.duplicateFrom == null
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(
              widget.duplicateFrom!.endDate.difference(widget.duplicateFrom!.startDate),
            ));
  late bool _notifyExceeded = _source?.notifyExceeded ?? true;
  late bool _notifyNearLimit = _source?.notifyNearLimit ?? true;
  late List<BudgetCategoryAllocation> _categories = List.of(_source?.categories ?? const []);

  TransactionCategory? _newCategory;
  final _newAmountController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameController, _limitController, _newAmountController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _noteController.dispose();
    _newAmountController.dispose();
    super.dispose();
  }

  double get _limit => parseAmountInput(_limitController.text);
  double get _newAmount => parseAmountInput(_newAmountController.text);
  double get _assigned => _categories.fold(0, (sum, c) => sum + c.limitAmount);

  bool get _step0Valid => _nameController.text.trim().isNotEmpty && _limit > 0 && _endDate != null;
  bool get _step2Valid => _type == BudgetType.general || _categories.isNotEmpty;

  bool get _canContinue => switch (_step) {
        0 => _step0Valid,
        1 => true,
        2 => _step2Valid,
        _ => true,
      };

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickNewCategory() async {
    final picked = await showCategoryPicker(context, type: TransactionType.expense);
    if (picked != null) setState(() => _newCategory = picked);
  }

  void _addAllocation() {
    if (_newCategory == null || _newAmount <= 0) return;
    setState(() {
      _categories = [
        ..._categories.where((c) => c.categoryId != _newCategory!.id),
        BudgetCategoryAllocation(
          categoryId: _newCategory!.id,
          categoryLabel: _newCategory!.label,
          limitAmount: _newAmount,
        ),
      ];
      _newCategory = null;
      _newAmountController.clear();
    });
  }

  void _removeAllocation(String categoryId) {
    setState(() => _categories = _categories.where((c) => c.categoryId != categoryId).toList());
  }

  void _next() {
    if (!_canContinue) return;
    if (_step == _stepCount - 1) {
      _save();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final existing = widget.existingBudget;
    final budget = Budget(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      limitAmount: _limit,
      startDate: existing?.startDate ?? DateTime.now(),
      endDate: _endDate!,
      note: _noteController.text.trim(),
      notifyExceeded: _notifyExceeded,
      notifyNearLimit: _notifyNearLimit,
      status: existing?.status ?? BudgetStatus.active,
      categories: _type == BudgetType.byCategory ? _categories : const [],
      createdAt: existing?.createdAt ?? DateTime.now(),
      pausedAt: existing?.pausedAt,
      resumedAt: existing?.resumedAt,
    );
    try {
      if (existing != null) {
        await widget.repository.updateBudget(existing.id, budget);
      } else {
        await widget.repository.createBudget(budget);
      }
      if (!mounted) return;
      showAppSnackBar(context, existing != null ? 'Presupuesto actualizado' : 'Presupuesto creado');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos guardar el presupuesto: $e', isError: true);
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
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          title: Text(_isEditing ? 'Editar presupuesto' : 'Crear presupuesto'),
          centerTitle: false,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.lg),
                child: _StepProgressBar(step: _step, stepCount: _stepCount),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    HitoSpacing.lg,
                    HitoSpacing.md,
                    HitoSpacing.lg,
                    HitoSpacing.lg,
                  ),
                  child: switch (_step) {
                    0 => _BasicsStep(
                        nameController: _nameController,
                        limitController: _limitController,
                        noteController: _noteController,
                        endDate: _endDate,
                        onPickDate: _pickEndDate,
                      ),
                    1 => _TypeStep(selected: _type, onChanged: (t) => setState(() => _type = t)),
                    2 => _type == BudgetType.byCategory
                        ? _CategoriesStep(
                            limit: _limit,
                            assigned: _assigned,
                            categories: _categories,
                            newCategory: _newCategory,
                            newAmountController: _newAmountController,
                            onPickCategory: _pickNewCategory,
                            onAdd: (_newCategory != null && _newAmount > 0) ? _addAllocation : null,
                            onRemove: _removeAllocation,
                          )
                        : _GeneralInfoStep(limit: _limit),
                    _ => _ConfirmStep(
                        name: _nameController.text.trim(),
                        type: _type,
                        limit: _limit,
                        endDate: _endDate,
                        categoryCount: _categories.length,
                        notifyExceeded: _notifyExceeded,
                        notifyNearLimit: _notifyNearLimit,
                        onNotifyExceededChanged: (v) => setState(() => _notifyExceeded = v),
                        onNotifyNearLimitChanged: (v) => setState(() => _notifyNearLimit = v),
                      ),
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  HitoSpacing.lg,
                  HitoSpacing.sm,
                  HitoSpacing.lg,
                  HitoSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: Text(_step == 0 ? 'Cancelar' : '← Atrás'),
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: (_saving || !_canContinue) ? null : _next,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _step == _stepCount - 1
                                    ? (_isEditing ? 'Guardar cambios' : 'Confirmar presupuesto')
                                    : 'Continuar →',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step, required this.stepCount});

  final int step;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HitoSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < stepCount; i++) ...[
            if (i > 0) const SizedBox(width: HitoSpacing.xs),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 4,
                  backgroundColor: recessedColor(theme),
                  color: i <= step ? theme.colorScheme.primary : recessedColor(theme),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    required this.nameController,
    required this.limitController,
    required this.noteController,
    required this.endDate,
    required this.onPickDate,
  });

  final TextEditingController nameController;
  final TextEditingController limitController;
  final TextEditingController noteController;
  final DateTime? endDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Empecemos con lo esencial', style: theme.textTheme.headlineLarge),
        const SizedBox(height: HitoSpacing.xs),
        Text(
          'Podés ajustar todo esto después.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: HitoSpacing.lg),
        _FieldLabel('Nombre'),
        const SizedBox(height: HitoSpacing.xs),
        _PlainTextField(controller: nameController, hint: 'Ej. Mi mes de octubre'),
        const SizedBox(height: HitoSpacing.md),
        _FieldLabel('Monto límite total'),
        const SizedBox(height: HitoSpacing.xs),
        _PlainTextField(
          controller: limitController,
          hint: '\$ 0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsInputFormatter()],
          prefixText: '\$ ',
        ),
        const SizedBox(height: HitoSpacing.md),
        _FieldLabel('Fecha límite'),
        const SizedBox(height: HitoSpacing.xs),
        InkWell(
          onTap: onPickDate,
          borderRadius: BorderRadius.circular(HitoRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.md),
            decoration: BoxDecoration(
              color: recessedColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    endDate == null ? 'Elegir fecha' : formatGoalDate(endDate!),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (endDate != null) ...[
          const SizedBox(height: HitoSpacing.xs),
          Text(
            _longDate(endDate!),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: HitoSpacing.md),
        _FieldLabel('Nota (opcional)'),
        const SizedBox(height: HitoSpacing.xs),
        _PlainTextField(
          controller: noteController,
          hint: 'Ej. Un mes tranquilo, sin viajes',
          maxLines: 3,
        ),
      ],
    );
  }

  static String _longDate(DateTime date) {
    const weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} de ${months[date.month - 1]}';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
      decoration: BoxDecoration(
        color: recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          prefixText: prefixText,
          contentPadding: const EdgeInsets.symmetric(vertical: HitoSpacing.md),
        ),
      ),
    );
  }
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.selected, required this.onChanged});

  final BudgetType selected;
  final ValueChanged<BudgetType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Cómo querés organizarlo?', style: theme.textTheme.headlineLarge),
        const SizedBox(height: HitoSpacing.xs),
        Text(
          'Podés cambiar el tipo más adelante.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: HitoSpacing.lg),
        _TypeOptionCard(
          icon: Icons.pie_chart_outline,
          title: 'Por categorías',
          description:
              'Asigná un monto a cada categoría (Comida, Transporte, etc). Ideal para tener más visibilidad.',
          selected: selected == BudgetType.byCategory,
          onTap: () => onChanged(BudgetType.byCategory),
        ),
        const SizedBox(height: HitoSpacing.sm),
        _TypeOptionCard(
          icon: Icons.eco_outlined,
          title: 'Presupuesto general',
          description:
              'Se monitorea el total acumulado sin distinguir categorías. Más simple, menos detalle.',
          selected: selected == BudgetType.general,
          onTap: () => onChanged(BudgetType.general),
        ),
      ],
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HitoSpacing.md),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.lg),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? null : cardShadow(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesStep extends StatelessWidget {
  const _CategoriesStep({
    required this.limit,
    required this.assigned,
    required this.categories,
    required this.newCategory,
    required this.newAmountController,
    required this.onPickCategory,
    required this.onAdd,
    required this.onRemove,
  });

  final double limit;
  final double assigned;
  final List<BudgetCategoryAllocation> categories;
  final TransactionCategory? newCategory;
  final TextEditingController newAmountController;
  final VoidCallback onPickCategory;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = limit - assigned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asigná categorías', style: theme.textTheme.headlineLarge),
        const SizedBox(height: HitoSpacing.md),
        Row(
          children: [
            Expanded(child: _MiniStat(label: 'Total', value: formatCurrency(limit))),
            Expanded(child: _MiniStat(label: 'Asignado', value: formatCurrency(assigned))),
            Expanded(
              child: _MiniStat(
                label: 'Restante',
                value: formatCurrency(remaining),
                valueColor: remaining < 0 ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: HitoSpacing.lg),
        Text('Nueva asignación', style: theme.textTheme.headlineMedium),
        const SizedBox(height: HitoSpacing.sm),
        InkWell(
          onTap: onPickCategory,
          borderRadius: BorderRadius.circular(HitoRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(HitoSpacing.md),
            decoration: BoxDecoration(
              color: recessedColor(theme),
              borderRadius: BorderRadius.circular(HitoRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  newCategory?.icon ?? Icons.category_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: Text(newCategory?.label ?? 'Elegí categoría', style: theme.textTheme.bodyLarge),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md),
          decoration: BoxDecoration(
            color: recessedColor(theme),
            borderRadius: BorderRadius.circular(HitoRadius.md),
          ),
          child: TextField(
            controller: newAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              hintText: '\$ Monto',
              contentPadding: EdgeInsets.symmetric(vertical: HitoSpacing.md),
            ),
          ),
        ),
        const SizedBox(height: HitoSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir'),
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: HitoSpacing.lg),
          Text(
            'CATEGORÍAS ASIGNADAS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: HitoSpacing.sm),
          for (final c in categories) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.sm),
              decoration: BoxDecoration(
                color: cardColor(theme),
                borderRadius: BorderRadius.circular(HitoRadius.md),
                boxShadow: cardShadow(),
              ),
              child: Row(
                children: [
                  Icon(
                    findCategory(c.categoryId)?.icon ?? Icons.category_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: HitoSpacing.sm),
                  Expanded(child: Text(c.categoryLabel, style: theme.textTheme.bodyMedium)),
                  Text(
                    formatCurrency(c.limitAmount),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    tooltip: 'Quitar',
                    onPressed: () => onRemove(c.categoryId),
                    icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}

class _GeneralInfoStep extends StatelessWidget {
  const _GeneralInfoStep({required this.limit});

  final double limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Cómo querés organizarlo?', style: theme.textTheme.headlineLarge),
        const SizedBox(height: HitoSpacing.xs),
        Text(
          'Podés cambiar el tipo más adelante.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: HitoSpacing.lg),
        Text('Presupuesto general', style: theme.textTheme.headlineMedium),
        const SizedBox(height: HitoSpacing.xs),
        Text(
          'Se monitoreará el total acumulado sin distinguir categorías.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: HitoSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HitoSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(HitoRadius.md),
          ),
          child: Text(
            'Cada gasto que registres se descontará del límite total de ${formatCurrency(limit)}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.name,
    required this.type,
    required this.limit,
    required this.endDate,
    required this.categoryCount,
    required this.notifyExceeded,
    required this.notifyNearLimit,
    required this.onNotifyExceededChanged,
    required this.onNotifyNearLimitChanged,
  });

  final String name;
  final BudgetType type;
  final double limit;
  final DateTime? endDate;
  final int categoryCount;
  final bool notifyExceeded;
  final bool notifyNearLimit;
  final ValueChanged<bool> onNotifyExceededChanged;
  final ValueChanged<bool> onNotifyNearLimitChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notificaciones y confirmación', style: theme.textTheme.headlineLarge),
        const SizedBox(height: HitoSpacing.xs),
        Text(
          'Avisos suaves, cuando los necesités.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: HitoSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: cardColor(theme),
            borderRadius: BorderRadius.circular(HitoRadius.md),
            boxShadow: cardShadow(),
          ),
          child: Column(
            children: [
              _NotifyRow(
                icon: Icons.trending_up,
                title: 'Riesgo de exceder',
                subtitle: 'Aviso cuando estés cerca del 80% del límite.',
                value: notifyNearLimit,
                onChanged: onNotifyNearLimitChanged,
              ),
              Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              _NotifyRow(
                icon: Icons.error_outline,
                title: 'Presupuesto excedido',
                subtitle: 'Aviso cuando superes el 100%. Sin juicio, con opciones.',
                value: notifyExceeded,
                onChanged: onNotifyExceededChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: HitoSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HitoSpacing.md),
          decoration: BoxDecoration(
            color: recessedColor(theme),
            borderRadius: BorderRadius.circular(HitoRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMEN',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: HitoSpacing.xs),
              Text(
                name.isEmpty ? 'Sin nombre' : name,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Hasta ${formatCurrency(limit)} · vence ${endDate == null ? '-' : formatGoalDate(endDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                type == BudgetType.byCategory
                    ? '$categoryCount categorías asignadas'
                    : 'Presupuesto general',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifyRow extends StatelessWidget {
  const _NotifyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(HitoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
