import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';

/// Pantalla de apertura. Avanza sola después de [holdDuration].
/// El wordmark usa Monomakh (fuente custom, ver pubspec.yaml) — es la
/// única excepción a Manrope, reservada al logotipo de marca, no a la UI.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.holdDuration = const Duration(milliseconds: 1400),
  });

  final VoidCallback onFinished;
  final Duration holdDuration;

  @override
  Widget build(BuildContext context) {
    Future.delayed(holdDuration, onFinished);

    return Scaffold(
      backgroundColor: HitoColors.splashBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _StarField()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoMark(
                  diameter: 64,
                  backgroundColor: HitoColors.splashForeground,
                  foregroundColor: HitoColors.splashBackground,
                ),
                const SizedBox(height: HitoSpacing.md),
                const Text(
                  'milestone',
                  style: TextStyle(
                    fontFamily: 'Monomakh',
                    fontSize: 32,
                    color: HitoColors.splashForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    final random = Random(7);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(14, (i) {
            final dx = random.nextDouble() * constraints.maxWidth;
            final dy = random.nextDouble() * constraints.maxHeight;
            final size = 4.0 + random.nextDouble() * 4;
            return Positioned(
              left: dx,
              top: dy,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: HitoColors.secondaryDark.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
