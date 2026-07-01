import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

/// Pantalla de apertura. Anima la entrada del lockup (círculo+cerdito+
/// nombre) y avanza sola cuando termina.
///
/// La secuencia calca el prototipo de Figma (3000ms totales, ver
/// `HitoMotion.splashLockupAnimation`): primero entra el conjunto
/// círculo+texto con un fade + scale + settle de posición corto (los
/// primeros ~900ms), y por separado el cerdito de adentro del círculo
/// hace su propia entrada más elaborada — spin + scale con rebote —
/// que arranca un poco después y tarda casi toda la animación en
/// asentarse. El wordmark usa Monomakh (fuente custom, ver
/// pubspec.yaml) — es la única excepción a Manrope, reservada al
/// logotipo de marca, no a la UI.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.holdDuration = HitoMotion.splashHold,
  });

  final VoidCallback onFinished;

  /// Pausa después de que termina de entrar el lockup, antes de navegar.
  final Duration holdDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: HitoMotion.splashLockupAnimation,
  );

  // Lockup completo (círculo + nombre) — entrada corta, primeros ~900ms.
  late final _lockupOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
  );
  late final _lockupOffset =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        ),
      );
  late final _lockupScale = Tween<double>(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ),
  );

  // Cerdito adentro del círculo — entra después, con spin + rebote,
  // y tarda casi toda la animación en asentarse.
  late final _pigCurve = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
  );
  late final _pigOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.45, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    Future.delayed(
      (reduceMotion ? Duration.zero : HitoMotion.splashLockupAnimation) +
          widget.holdDuration,
      widget.onFinished,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HitoColors.splashBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _StarField()),
          Center(
            child: FadeTransition(
              opacity: _lockupOpacity,
              child: SlideTransition(
                position: _lockupOffset,
                child: ScaleTransition(
                  scale: _lockupScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedPigLogo(
                        opacity: _pigOpacity,
                        curve: _pigCurve,
                        diameter: 64,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo de fondo estático (entra junto con el resto del lockup) con
/// el cerdito adentro animado por separado: aparece con scale 0.4→1
/// y un pequeño giro que se pasa de largo y vuelve (por eso
/// `Curves.easeOutBack` en vez de un ease simple) — el efecto de
/// "rebote" que el prototipo de Figma resuelve con keyframes de
/// escala + rotación superpuestos.
class _AnimatedPigLogo extends StatelessWidget {
  const _AnimatedPigLogo({
    required this.opacity,
    required this.curve,
    required this.diameter,
  });

  final Animation<double> opacity;
  final Animation<double> curve;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: HitoColors.splashForeground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, child) {
          final t = curve.value;
          return Opacity(
            opacity: opacity.value,
            child: Transform.rotate(
              angle: (1 - t) * -0.35,
              child: Transform.scale(scale: t, child: child),
            ),
          );
        },
        child: SvgPicture.asset(
          'assets/branding/pig_mark.svg',
          width: diameter * 0.62,
          height: diameter * 0.62,
          colorFilter: const ColorFilter.mode(
            HitoColors.splashBackground,
            BlendMode.srcIn,
          ),
        ),
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
