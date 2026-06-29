import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/home_models.dart';

/// Un movimiento de ahorro positivo usa el rol `tertiary` (salvia,
/// "indicadores de progreso/crecimiento" en el sistema visual) — nunca
/// `success`, que está reservado a confirmaciones técnicas.
class MovementTile extends StatelessWidget {
  const MovementTile({super.key, required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sign = movement.isPositive ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HitoSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.tertiaryContainer,
            child: Icon(
              movement.isPositive ? Icons.add : Icons.remove,
              size: 18,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.title, style: theme.textTheme.bodyLarge),
                Text(
                  movement.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${formatCurrency(movement.amount)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
