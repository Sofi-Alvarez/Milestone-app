import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AllDoneScreen extends StatelessWidget {
  const AllDoneScreen({super.key, required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HitoSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: HitoSpacing.lg),
              Text(
                'Todo listo',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.sm),
              Text(
                'Cuando quieras, damos el primer paso juntos.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onEnter,
                  child: const Text('Comenzar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
