import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';

String formatGoalDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Card "Simulador de progreso" — compartida por Crear meta y Editar meta.
class SimulatorProgressCard extends StatelessWidget {
  const SimulatorProgressCard({
    super.key,
    required this.target,
    required this.saved,
    required this.targetDate,
    required this.suggestedDaily,
  });

  final double target;
  final double saved;
  final DateTime? targetDate;
  final double suggestedDaily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(HitoRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulador de progreso',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SimulatorStat(
                  label: 'Meta de ahorro',
                  value: formatCurrency(target),
                ),
              ),
              Expanded(
                child: _SimulatorStat(
                  label: 'Ahorro inicial',
                  value: formatCurrency(saved),
                ),
              ),
              Expanded(
                child: _SimulatorStat(
                  label: 'Fecha objetivo',
                  value: targetDate == null ? 'Sin fecha' : formatGoalDate(targetDate!),
                ),
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Ahorro sugerido',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Text(
                formatCurrency(suggestedDaily),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / día',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimulatorStat extends StatelessWidget {
  const _SimulatorStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Fila "estática hasta que se edita": muestra el valor como texto con un
/// lápiz al lado; tocar el lápiz (o el texto) enfoca un TextField con el
/// teclado correspondiente (alfabético o numérico). Al perder el foco
/// vuelve a mostrarse como texto.
class EditableGoalField extends StatefulWidget {
  const EditableGoalField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.keyboardType,
    this.leading,
    this.isAmount = false,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextInputType keyboardType;
  final Widget? leading;
  final bool isAmount;

  @override
  State<EditableGoalField> createState() => _EditableGoalFieldState();
}

class _EditableGoalFieldState extends State<EditableGoalField> {
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

  String get _displayValue {
    if (widget.controller.text.isEmpty) return widget.placeholder;
    if (widget.isAmount) {
      final parsed = double.tryParse(widget.controller.text.replaceAll(',', '.'));
      if (parsed != null) return formatCurrency(parsed);
    }
    return widget.controller.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: HitoSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_editing)
                TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: widget.keyboardType,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => widget.focusNode.unfocus(),
                  style: theme.textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              else
                Text(_displayValue, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() => _editing = true);
            widget.focusNode.requestFocus();
          },
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
      ],
    );
  }
}

/// Fila "Fecha límite" — tocar en cualquier parte abre el date picker.
class GoalDateField extends StatelessWidget {
  const GoalDateField({super.key, required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha límite',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  date == null ? 'Sin fecha' : formatGoalDate(date!),
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.calendar_today_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
