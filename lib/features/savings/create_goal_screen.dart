import 'package:flutter/material.dart';

import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';
import 'goal_created_screen.dart';
import 'widgets/goal_form_fields.dart';

void openCreateGoalScreen(
  BuildContext context, {
  required GoalsRepository repository,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateGoalScreen(repository: repository),
    ),
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

  Future<void> _createGoal() async {
    FocusScope.of(context).unfocus();
    final title =
        _titleController.text.trim().isEmpty ? 'Sin título' : _titleController.text.trim();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pudimos crear la meta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
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
                  label: 'Monto ahorrado',
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
              onPressed: _saving ? null : _createGoal,
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
