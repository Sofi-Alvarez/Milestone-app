import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HitoSpacing.lg,
            vertical: HitoSpacing.xl,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoMark(diameter: 88),
              const SizedBox(height: HitoSpacing.lg),
              Text(
                'Bienvenido',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.sm),
              Text(
                'Un espacio para entender tu relación con el dinero '
                'y sentirte más tranquilo día a día.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              FloatingActionButton(
                onPressed: onContinue,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
