import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card seleccionable con ícono + título + check al elegirla — reemplaza
/// las dos copias que existían por separado (tipo de presupuesto y tema
/// del onboarding), donde solo una de las dos dibujaba el ícono de check.
class SelectableOptionCard extends StatelessWidget {
  const SelectableOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  /// Subtítulo opcional debajo del título.
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HitoRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HitoSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.lg),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? null : cardShadow(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: HitoSpacing.sm),
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
