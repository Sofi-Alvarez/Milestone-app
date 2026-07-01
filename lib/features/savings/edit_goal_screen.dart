import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/logo_mark.dart';
import '../home/models/home_models.dart';
import 'widgets/goal_form_fields.dart';

void openEditGoalScreen(
  BuildContext context, {
  required GoalsRepository repository,
  required Goal goal,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EditGoalScreen(repository: repository, goal: goal),
    ),
  );
}

class EditGoalScreen extends StatefulWidget {
  const EditGoalScreen({
    super.key,
    required this.repository,
    required this.goal,
  });

  final GoalsRepository repository;
  final Goal goal;

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late final _titleController = TextEditingController(text: widget.goal.title);
  late final _targetController = TextEditingController(
    text: widget.goal.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
  );
  late final _savedController = TextEditingController(
    text: widget.goal.savedAmount.toStringAsFixed(2).replaceAll('.', ','),
  );

  final _titleFocus = FocusNode();
  final _targetFocus = FocusNode();
  final _savedFocus = FocusNode();

  late DateTime? _targetDate = widget.goal.targetDate;
  bool _saving = false;

  bool _titleTouched = false;
  bool _targetTouched = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_titleController, _targetController, _savedController]) {
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

  double get _suggestedDaily {
    if (_targetDate == null) return 0;
    final remaining = _target - _saved;
    if (remaining <= 0) return 0;
    final days = _targetDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return remaining;
    return remaining / days;
  }

  bool get _savedExceedsTarget => _target > 0 && _saved > _target;

  /// El monto ahorrado es el único campo que puede quedar en cero.
  bool get _isFormComplete =>
      _titleController.text.trim().isNotEmpty && _target > 0 && _targetDate != null;

  String? get _titleError =>
      _titleTouched && _titleController.text.trim().isEmpty
          ? 'Ponele un nombre a tu meta'
          : null;

  String? get _targetError =>
      _targetTouched && _target <= 0 ? 'El monto de meta tiene que ser mayor a \$0' : null;

  bool get _hasChanges {
    return _titleController.text != widget.goal.title ||
        _target != widget.goal.targetAmount ||
        _saved != widget.goal.savedAmount ||
        _targetDate != widget.goal.targetDate;
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

  Future<void> _saveChanges() async {
    if (_savedExceedsTarget || !_isFormComplete) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.repository.updateGoal(
        widget.goal.id,
        title: _titleController.text.trim().isEmpty
            ? 'Sin título'
            : _titleController.text.trim(),
        targetAmount: _target,
        savedAmount: _saved,
        targetDate: _targetDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(context, 'Cambios guardados');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'No pudimos guardar: $e', isError: true);
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
    required Future<void> Function() onConfirmed,
  }) async {
    final confirmed = await confirmDialog(
      context,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (confirmed) await onConfirmed();
  }

  void _delete() => _confirmAndRun(
        title: '¿Eliminar meta?',
        body: 'La meta se eliminará de forma permanente.',
        confirmLabel: 'Eliminar',
        destructive: true,
        onConfirmed: () async {
          await widget.repository.deleteGoal(widget.goal.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          showAppSnackBar(context, 'Meta eliminada');
        },
      );

  void _pause() => _confirmAndRun(
        title: '¿Pausar meta?',
        body: 'La meta se mantendrá pausada hasta que la reanudes.',
        confirmLabel: 'Pausar',
        onConfirmed: () async {
          await widget.repository.pauseGoal(widget.goal.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          showAppSnackBar(context, 'Meta pausada');
        },
      );

  void _restart() => _confirmAndRun(
        title: '¿Reiniciar meta?',
        body: 'La meta se reiniciará y comenzará de sin ningún ahorro.',
        confirmLabel: 'Reiniciar',
        onConfirmed: () async {
          await widget.repository.restartGoal(widget.goal.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          showAppSnackBar(context, 'Meta reiniciada');
        },
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaused = widget.goal.lifecycle == GoalLifecycle.paused;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: pageColor(theme),
        appBar: AppBar(
          title: const Text('Editar meta'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Eliminar meta',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
            if (isPaused)
              IconButton(
                tooltip: 'Reiniciar meta',
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
              )
            else
              IconButton(
                tooltip: 'Pausar meta',
                onPressed: _pause,
                icon: const Icon(Icons.pause_circle_outline),
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
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de meta',
                  controller: _targetController,
                  focusNode: _targetFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (_targetError != null) ...[
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    _targetError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de ahorro inicial',
                  controller: _savedController,
                  focusNode: _savedFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              onPressed: (_hasChanges && !_saving && !_savedExceedsTarget && _isFormComplete)
                  ? _saveChanges
                  : null,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar cambios'),
            ),
          ),
        ),
      ),
    );
  }
}
