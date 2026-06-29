import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HitoBottomNavBar extends StatelessWidget {
  const HitoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, label: 'Inicio'),
    (icon: Icons.savings_outlined, label: 'Ahorro'),
    (icon: Icons.add, label: 'Registrar'),
    (icon: Icons.description_outlined, label: 'Historial'),
    (icon: Icons.person_outline, label: 'Perfil'),
  ];

  static const _centralIndex = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: HitoSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: HitoColors.neutral900Light.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = index == currentIndex;
                final isCentral = index == _centralIndex;

                return _NavItem(
                  label: item.label,
                  isSelected: isSelected,
                  showIndicator: !isCentral,
                  onTap: () => onTap(index),
                  // El ícono central flota por arriba de la barra (ver
                  // Positioned más abajo), así que aquí dejamos el espacio.
                  child: isCentral
                      ? const SizedBox(width: 24, height: 24)
                      : Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                );
              }),
            ),
          ),
        ),
        Positioned(
          top: -20,
          child: GestureDetector(
            onTap: () => onTap(_centralIndex),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _items[_centralIndex].icon,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.showIndicator = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIndicator)
              Container(
                width: 48,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(HitoRadius.lg),
                ),
                child: child,
              )
            else
              child,
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
