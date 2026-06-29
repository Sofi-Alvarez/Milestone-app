import 'package:flutter/material.dart';

import '../../data/goal.dart';
import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';
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

  @override
  void initState() {
    super.initState();
    for (final controller in [_titleController, _targetController, _savedController]) {
      controller.addListener(() => setState(() {}));
    }
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

  double _parseAmount(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  double get _target => _parseAmount(_targetController.text);
  double get _saved => _parseAmount(_savedController.text);

  double get _suggestedDaily {
    if (_targetDate == null) return 0;
    final remaining = _target - _saved;
    if (remaining <= 0) return 0;
    final days = _targetDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return remaining;
    return remaining / days;
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pudimos guardar: $e')),
      );
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) await onConfirmed();
  }

  void _delete() => _confirmAndRun(
        title: '¿Eliminar meta?',
        body: 'La meta se eliminará de forma permanente.',
        confirmLabel: 'Eliminar',
        onConfirmed: () async {
          await widget.repository.deleteGoal(widget.goal.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta eliminada')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta pausada')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta reiniciada')),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaused = widget.goal.lifecycle == GoalLifecycle.paused;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Editar meta'),
          centerTitle: false,
          actions: [
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
            if (isPaused)
              IconButton(onPressed: _restart, icon: const Icon(Icons.refresh))
            else
              IconButton(onPressed: _pause, icon: const Icon(Icons.pause_circle_outline)),
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
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de meta',
                  controller: _targetController,
                  focusNode: _targetFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: HitoSpacing.md),
                EditableGoalField(
                  label: 'Monto de ahorro inicial',
                  controller: _savedController,
                  focusNode: _savedFocus,
                  placeholder: '\$ 00,00',
                  isAmount: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
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
              onPressed: (_hasChanges && !_saving) ? _saveChanges : null,
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
