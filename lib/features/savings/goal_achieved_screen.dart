import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../data/goals_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';
import 'create_goal_screen.dart';

void openGoalAchievedScreen(
  BuildContext context, {
  required GoalsRepository repository,
  required String goalTitle,
}) {
  // `push` (no pushReplacement): tiene que apilarse arriba de la pantalla
  // de Ahorro, no reemplazarla — si no, "Volver a Ahorro"/"volver al
  // inicio" no tienen a qué pantalla raíz volver (ver popUntil isFirst
  // en los botones de esta pantalla y de GoalCreatedScreen).
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          GoalAchievedScreen(repository: repository, goalTitle: goalTitle),
    ),
  );
}

class GoalAchievedScreen extends StatefulWidget {
  const GoalAchievedScreen({
    super.key,
    required this.repository,
    required this.goalTitle,
  });

  final GoalsRepository repository;
  final String goalTitle;

  @override
  State<GoalAchievedScreen> createState() => _GoalAchievedScreenState();
}

class _GoalAchievedScreenState extends State<GoalAchievedScreen> {
  late final _confettiController =
      ConfettiController(duration: const Duration(seconds: 4));

  bool _playedConfetti = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta "reducir movimiento" del sistema — el confetti es
    // puramente decorativo, la celebración sigue siendo clara sin él.
    if (!_playedConfetti) {
      _playedConfetti = true;
      if (!MediaQuery.of(context).disableAnimations) {
        _confettiController.play();
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];

    return Scaffold(
      backgroundColor: pageColor(theme),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(HitoSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  const Center(child: LogoMark(diameter: 96)),
                  const SizedBox(height: HitoSpacing.lg),
                  Text(
                    '¡Meta lograda!',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HitoSpacing.xs),
                  Text(
                    'Cumpliste "${widget.goalTitle}". Cada paso contó.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  FilledButton(
                    onPressed: () => openCreateGoalScreen(
                      context,
                      repository: widget.repository,
                    ),
                    child: const Text('Crear meta'),
                  ),
                  const SizedBox(height: HitoSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Volver a Ahorro'),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.3,
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}
