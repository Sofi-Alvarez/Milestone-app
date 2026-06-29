import 'package:flutter/material.dart';

/// Solo el porcentaje va dentro del anillo — el monto ("$X/$Y ARS") se
/// muestra aparte, debajo, para que no importa cuántas cifras tenga,
/// nunca se aprieta contra el círculo.
class GoalProgressDonut extends StatelessWidget {
  const GoalProgressDonut({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: theme.textTheme.displayMedium,
          ),
        ],
      ),
    );
  }
}
