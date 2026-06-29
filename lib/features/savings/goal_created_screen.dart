import 'package:flutter/material.dart';

import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';
import 'widgets/add_savings_sheet.dart';

class GoalCreatedScreen extends StatelessWidget {
  const GoalCreatedScreen({
    super.key,
    required this.title,
    required this.goalId,
    required this.repository,
  });

  final String title;
  final String goalId;
  final GoalsRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HitoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Center(child: LogoMark(diameter: 96)),
              const SizedBox(height: HitoSpacing.lg),
              Text(
                'Meta creada',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.xs),
              Text(
                'Hoy empezaste algo importante.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              Container(
                padding: const EdgeInsets.all(HitoSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(HitoRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip de ahorro',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Redondea tus gastos y guarda la diferencia.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: HitoSpacing.sm),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HitoSpacing.md),
              FilledButton(
                onPressed: () => addSavingsAndNotify(
                  context,
                  repository: repository,
                  goalId: goalId,
                ),
                child: const Text('Añadir ahorro'),
              ),
              const SizedBox(height: HitoSpacing.sm),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
