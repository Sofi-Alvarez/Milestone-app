import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Estructura compartida por las 3 variantes de card de meta (activa,
/// pausada, lograda) — mismo padding, borde y layout del encabezado,
/// para que ningún espaciado se desalinee entre variantes.
class GoalCardShell extends StatelessWidget {
  const GoalCardShell({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusLabelColor,
    required this.trailingValue,
    required this.trailingLabel,
    required this.middle,
    required this.footer,
  });

  final String title;
  final String statusLabel;
  final Color statusLabelColor;
  final String trailingValue;
  final String trailingLabel;

  /// Barra de progreso + línea de nota; varía por variante pero ocupa
  /// el mismo lugar en la estructura.
  final Widget middle;

  /// Fila de botones de acción, debajo del divisor.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      padding: const EdgeInsets.all(HitoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: HitoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trailingValue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    trailingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: HitoSpacing.md),
          middle,
          Divider(
            height: HitoSpacing.lg,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          footer,
        ],
      ),
    );
  }
}

/// Fila de barra de progreso + porcentaje, compartida por las 3 variantes.
class GoalProgressRow extends StatelessWidget {
  const GoalProgressRow({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HitoRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: pageColor(theme),
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: HitoSpacing.sm),
        Text('%${(progress * 100).round()}', style: theme.textTheme.labelLarge),
      ],
    );
  }
}

/// Fila de 1 o 2 botones de texto en el footer, alineados a la izquierda
/// (nunca centrados ni estirados a todo el ancho) para que la posición
/// sea consistente entre variantes con uno o dos botones.
class GoalCardFooter extends StatelessWidget {
  const GoalCardFooter({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: HitoSpacing.md),
          buttons[i],
        ],
      ],
    );
  }
}
