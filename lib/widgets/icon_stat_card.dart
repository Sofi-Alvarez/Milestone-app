import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'transaction_icon_avatar.dart';

/// Card de "ícono + label + valor" — reemplaza `ScheduledCounterCard`
/// (Historial) y `AnalysisCard` (Metas), que eran casi el mismo
/// componente implementado por separado con distinto orden de
/// label/valor. Acá el orden es siempre label arriba, valor abajo.
class IconStatCard extends StatelessWidget {
  const IconStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconBackground,
    this.width,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Color del ícono. Por defecto, `onTertiaryContainer` (uso en Metas).
  final Color? iconColor;

  /// Si se especifica, el ícono se dibuja dentro de un círculo de este
  /// color (uso en Historial: Programado/Realizado/Pendiente). Si es
  /// `null`, el ícono se dibuja sin fondo.
  final Color? iconBackground;

  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor =
        iconColor ?? theme.colorScheme.onTertiaryContainer;
    return Container(
      width: width,
      padding: const EdgeInsets.all(HitoSpacing.md),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconBackground != null)
            TransactionIconAvatar(
              icon: icon,
              background: iconBackground!,
              iconColor: resolvedIconColor,
            )
          else
            Icon(icon, size: 24, color: resolvedIconColor),
          const SizedBox(height: HitoSpacing.sm),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
