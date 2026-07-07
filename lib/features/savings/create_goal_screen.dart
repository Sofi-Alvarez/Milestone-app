import 'package:flutter/material.dart';

import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/logo_mark.dart';
import '../home/models/home_models.dart';
import 'goal_created_screen.dart';
import 'widgets/goal_form_fields.dart';

void openCreateGoalScreen(
  BuildContext context, {
  required GoalsRepository repository,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CreateGoalScreen(repository: repository)),
  );
}

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, required this.repository});

  final GoalsRepository repository;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();

  final _titleFocus = FocusNode();
  final _targetFocus = FocusNode();
  final _savedFocus = FocusNode();

  DateTime? _targetDate;

  // Validación on-blur: el error solo aparece después de que el
  // usuario salió del campo, nunca antes de que interactúe con él.
  bool _titleTouched = false;
  bool _targetTouched = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _titleController,
      _targetController,
      _savedController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) setState(() => _titleTouched = true);
    });
    _targetFocus.addListener(() {
      if (!_targetFocus.hasFocus) setState(() => _targetTouched = true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _titleFocus.dispose();
    _targetFocus.dispose();
    _savedFocus.dispose();
    super.dispose();
  }

  double get _target => parseAmountInput(_targetController.text);
  double get _saved => parseAmountInput(_savedController.text);
  bool get _savedExceedsTarget => _target > 0 && _saved > _target;

  /// El monto ahorrado es el único campo que puede quedar en cero.
  bool get _isFormComplete =>
      _titleController.text.trim().isNotEmpty &&
      _target > 0 &&
      _targetDate != null;

  String? get _titleError =>
      _titleTouched && _titleController.text.trim().isEmpty
      ? 'Ponele un nombre a tu meta'
      : null;

  String? get _targetError => _targetTouched && _target <= 0
      ? 'El monto de meta tiene que ser mayor a \$0'
      : null;

  double get _suggestedDaily {
    if (_targetDate == null) return 0;
    final remaining = _target - _saved;
    if (remaining <= 0) return 0;
    final days = _targetDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return remaining;
    return remaining / days;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  bool _saving = false;

  /// El botón nunca queda realmente deshabilitado (`onPressed: null`) —
  /// así, si el usuario lo toca sin completar el formulario (o saltó
  /// directo a un campo sin pasar por el anterior, que nunca llegó a
  /// "tocarse"), igual vemos el tap y podemos mostrar los errores en
  /// vez de no reaccionar. El estilo sigue pareciendo deshabilitado
  /// mientras el formulario no sea válido (ver [_buttonStyle]).
  void _onSubmitPressed() {
    if (_saving) return;
    if (_savedExceedsTarget || !_isFormComplete) {
      setState(() {
        _titleTouched = true;
        _targetTouched = true;
      });
      return;
    }
    _createGoal();
  }

  Future<void> _createGoal() async {
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim().isEmpty
        ? 'Sin título'
        : _titleController.text.trim();
    setState(() => _saving = true);
    try {
      final goalId = await widget.repository.createGoal(
        title: title,
        targetAmount: _target,
        savedAmount: _saved,
        targetDate: _targetDate,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GoalCreatedScreen(
            title: title,
            goalId: goalId,
            repository: widget.repository,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos crear la meta: $e', isError: true);
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
          title: const Text('Crear meta'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SimulatorProgressCard(
                  target: _target,
                  saved: _saved,
                  targetDate: _targetDate,
                  suggestedDaily: _suggestedDaily,
                ),
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  leading: const LogoMark(diameter: 64, iconScale: 0.5),
                  label: 'Nombre de la meta',
                  controller: _titleController,
                  focusNode: _titleFocus,
                  placeholder: 'Sin título',
                  keyboardType: TextInputType.text,
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    _titleError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de meta',
                  controller: _targetController,
                  focusNode: _targetFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (_targetError != null) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    _targetError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto ahorrado',
                  controller: _savedController,
                  focusNode: _savedFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (_savedExceedsTarget) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    'El monto ahorrado no debe ser mayor al monto de meta.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: HitoSpacing.md),
                GoalDateField(date: _targetDate, onTap: _pickDate),
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
              style: (_savedExceedsTarget || !_isFormComplete)
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                    )
                  : null,
              onPressed: _onSubmitPressed,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear meta'),
            ),
          ),
        ),
      ),
    );
  }
}
