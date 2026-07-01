import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Última pantalla del onboarding — elegir claro/oscuro antes de
/// entrar. El cambio se aplica en vivo (mismo [ValueNotifier] que usa
/// Perfil), así que la vista previa de cada card ya es el tema real.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({
    super.key,
    required this.themeModeNotifier,
    required this.onFinish,
    required this.onBack,
  });

  final ValueNotifier<ThemeMode> themeModeNotifier;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HitoSpacing.lg,
            vertical: HitoSpacing.xl,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Elegí tu estilo',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.sm),
              Text(
                'Podés cambiarlo cuando quieras desde tu Perfil.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.xl),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) {
                  return Column(
                    children: [
                      _ThemeOptionCard(
                        icon: Icons.light_mode_outlined,
                        title: 'Claro',
                        selected: mode == ThemeMode.light,
                        onTap: () => themeModeNotifier.value = ThemeMode.light,
                      ),
                      const SizedBox(height: HitoSpacing.sm),
                      _ThemeOptionCard(
                        icon: Icons.dark_mode_outlined,
                        title: 'Oscuro',
                        selected: mode == ThemeMode.dark,
                        onTap: () => themeModeNotifier.value = ThemeMode.dark,
                      ),
                    ],
                  );
                },
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onFinish,
                  child: const Text('Terminar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

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
          color: selected ? theme.colorScheme.primaryContainer : cardColor(theme),
          borderRadius: BorderRadius.circular(HitoRadius.lg),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? null : cardShadow(),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: HitoSpacing.sm),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
