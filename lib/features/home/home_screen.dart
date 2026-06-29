import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'models/home_models.dart';
import 'widgets/goal_card.dart';
import 'widgets/movement_tile.dart';
import 'widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.goal,
    required this.movements,
    required this.monthlySavings,
    required this.availableMoney,
    this.onGoalAction,
  });

  final String userName;
  final SavingsGoal goal;
  final List<Movement> movements;
  final double monthlySavings;
  final double availableMoney;
  final VoidCallback? onGoalAction;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const headerHeight = 200.0;
    const cardOverlap = 110.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      bottomNavigationBar: HitoBottomNavBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: HitoSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(HitoRadius.lg),
                        bottomRight: Radius.circular(HitoRadius.lg),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: HitoSpacing.sm),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: HitoSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenido',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                  ),
                                  Text(
                                    widget.userName,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: HitoSpacing.lg),
                        Text(
                          'Tu progreso actual',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          widget.goal.isActive
                              ? 'Metas activas'
                              : 'Metas inactivas',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: headerHeight - cardOverlap,
                    left: HitoSpacing.lg,
                    right: HitoSpacing.lg,
                    child: GoalCard(
                      goal: widget.goal,
                      onPrimaryAction: widget.onGoalAction ?? () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: cardOverlap + HitoSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HitoSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Ahorro mensual',
                            value: formatCurrency(widget.monthlySavings),
                          ),
                        ),
                        const SizedBox(width: HitoSpacing.sm),
                        Expanded(
                          child: StatCard(
                            label: 'Dinero disponible',
                            value: formatCurrency(widget.availableMoney),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HitoSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Movimientos recientes',
                          style: theme.textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Ver todo'),
                        ),
                      ],
                    ),
                    if (widget.movements.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(HitoSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(HitoRadius.md),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No has registrado movimientos últimamente. '
                          '¡Empezá hoy!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HitoSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(HitoRadius.md),
                        ),
                        child: Column(
                          children: widget.movements
                              .map((m) => MovementTile(movement: m))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: HitoSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
