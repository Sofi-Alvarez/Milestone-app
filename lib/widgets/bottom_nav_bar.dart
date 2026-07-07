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

    return Container(
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
              // El ícono central lo cubre el FAB flotante de Scaffold (ver
              // HitoFab / floatingActionButtonLocation.centerDocked en
              // main_shell.dart), así que acá dejamos solo el espacio.
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
    );
  }
}

/// Botón circular "+" que flota mitad adentro / mitad afuera del bottom
/// nav. Vive como `Scaffold.floatingActionButton` (con
/// `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`)
/// en vez de vivir dentro de [HitoBottomNavBar] — así tiene su propia
/// región de Scaffold con hit-testing garantizado en toda su superficie
/// (antes, al flotar vía `Positioned(top: -20)` dentro del Stack de la
/// barra, la mitad que sobresalía quedaba fuera de los límites que
/// Scaffold le asigna a `bottomNavigationBar` y no respondía al tap) y
/// su propia sombra de Material, sin compartir ni interferir con la
/// sombra de la barra.
class HitoFab extends StatelessWidget {
  const HitoFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      shape: const CircleBorder(),
      elevation: HitoElevation.level3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        ),
      ),
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
