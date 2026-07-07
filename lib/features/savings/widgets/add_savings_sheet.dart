import 'package:flutter/material.dart';

import '../../../data/goals_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/app_snackbar.dart';
import '../goal_achieved_screen.dart';

/// Bottom sheet con teclado numérico custom para registrar un ahorro.
/// Se desliza hacia arriba, el fondo se oscurece (comportamiento default
/// de [showModalBottomSheet]), y se puede cerrar deslizando hacia abajo
/// o confirmando con el botón de enviar.
Future<double?> showAddSavingsSheet(BuildContext context) {
  return showAppBottomSheet<double>(
    context,
    builder: (context) => const _AddSavingsSheet(),
  );
}

/// Abre el sheet y persiste el monto en Firestore vía [repository].
/// Si ese ahorro completó la meta, navega a la pantalla de celebración
/// en vez de mostrar el snackbar — si no, muestra "Ahorro añadido"
/// (3 segundos, con acción de deshacer que resta el monto recién agregado).
Future<void> addSavingsAndNotify(
  BuildContext context, {
  required GoalsRepository repository,
  required String goalId,
  required String goalTitle,
}) async {
  final amount = await showAddSavingsSheet(context);
  if (amount == null || !context.mounted) return;

  bool justAchieved;
  try {
    justAchieved = await repository.addSavings(goalId, amount);
  } catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(context, 'No pudimos guardar el ahorro: $e', isError: true);
    return;
  }

  if (!context.mounted) return;

  if (justAchieved) {
    openGoalAchievedScreen(
      context,
      repository: repository,
      goalTitle: goalTitle,
    );
    return;
  }

  showAppToast(
    context,
    'Ahorro añadido',
    actionLabel: 'Deshacer',
    onAction: () => repository.addSavings(goalId, -amount),
  );
}

class _AddSavingsSheet extends StatefulWidget {
  const _AddSavingsSheet();

  @override
  State<_AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends State<_AddSavingsSheet> {
  String _digits = '';

  double get _amount {
    if (_digits.isEmpty) return 0;
    return int.parse(_digits) / 100;
  }

  void _onKeyTap(String key) {
    setState(() {
      if (_digits.length < 9) _digits += key;
    });
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _onConfirm() {
    if (_amount <= 0) return;
    Navigator.of(context).pop(_amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = formatAmountInput(_digits);

    return Container(
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(HitoRadius.lg),
          topRight: Radius.circular(HitoRadius.lg),
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
            Text('Añadir ahorro', style: theme.textTheme.labelLarge),
            const SizedBox(height: HitoSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$', style: theme.textTheme.headlineMedium),
                const SizedBox(width: HitoSpacing.xs),
                Text(formatted, style: theme.textTheme.displayMedium),
              ],
            ),
            const SizedBox(height: HitoSpacing.lg),
            _KeypadRow(
              labels: const ['1', '2', '3'],
              onKeyTap: _onKeyTap,
              trailing: _KeypadButton(
                label: '-',
                onTap: () {},
                background: recessedColor(theme),
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
            _KeypadRow(
              labels: const ['4', '5', '6'],
              onKeyTap: _onKeyTap,
              trailing: _KeypadButton(
                label: '␣',
                onTap: () {},
                background: recessedColor(theme),
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
            _KeypadRow(
              labels: const ['7', '8', '9'],
              onKeyTap: _onKeyTap,
              trailing: _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: _onBackspace,
                background: HitoColors.errorContainerLight,
                foreground: HitoColors.errorLight,
              ),
            ),
            const SizedBox(height: HitoSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _KeypadButton(label: ',', onTap: () {}),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: _KeypadButton(label: '0', onTap: () => _onKeyTap('0')),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: _KeypadButton(label: '.', onTap: () {}),
                ),
                const SizedBox(width: HitoSpacing.sm),
                Expanded(
                  child: _KeypadButton(
                    icon: Icons.send_rounded,
                    onTap: _onConfirm,
                    background: theme.colorScheme.primary,
                    foreground: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadRow extends StatelessWidget {
  const _KeypadRow({
    required this.labels,
    required this.onKeyTap,
    required this.trailing,
  });

  final List<String> labels;
  final ValueChanged<String> onKeyTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels) ...[
          Expanded(
            child: _KeypadButton(label: label, onTap: () => onKeyTap(label)),
          ),
          const SizedBox(width: HitoSpacing.sm),
        ],
        Expanded(child: trailing),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.background,
    this.foreground,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.4,
      child: Material(
        color: background ?? recessedColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(HitoRadius.md),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: foreground ?? theme.colorScheme.onSurface)
                : Text(
                    label!,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: foreground ?? theme.colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// "12345" (centavos) -> "123,45"
String formatAmountInput(String digits) {
  if (digits.isEmpty) return '00,00';
  final padded = digits.padLeft(3, '0');
  final wholePart = padded.substring(0, padded.length - 2);
  final centsPart = padded.substring(padded.length - 2);
  final wholeDigits = wholePart.isEmpty ? '0' : wholePart;

  final buffer = StringBuffer();
  for (var i = 0; i < wholeDigits.length; i++) {
    if (i > 0 && (wholeDigits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(wholeDigits[i]);
  }
  return '$buffer,$centsPart';
}
