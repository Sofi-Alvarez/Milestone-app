import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

/// Pantalla de apertura. Anima la entrada del lockup (círculo+cerdito+
/// nombre) y avanza sola cuando termina.
///
/// La secuencia calca el prototipo de Figma (3000ms totales, ver
/// `HitoMotion.splashLockupAnimation`), con dos grupos de keyframes
/// exportados tal cual:
///
/// **Lockup (círculo + cerdito + "milestone" juntos)** — retraso 918ms:
/// - Posición: desde +20px (abajo), 1000ms, cubic-bezier(0.3, -1.2, 0.45, 1)
///   (el y1 negativo es un rebote — se pasa de largo antes de asentar)
/// - Escala: 60% → 100%, 780ms, cubic-bezier(0.15, 0.52, 0.5, 1)
/// - Opacidad: 0% → 100%, 400ms, cubic-bezier(0.09, 0.55, 0.5, 1)
///
/// **Cerdito solo (adentro del círculo, ya visible)** — retraso y
/// duración acortados respecto al export de Figma (que tenía 1922ms de
/// retraso y 1000ms de movimiento — se sentía lento). Misma forma de
/// curva, más ágil: retraso 1300ms, movimiento 650ms, opacidad 250ms.
/// - Posición X: desde +30px (derecha), cubic-bezier(0.24, 0.08, 0.5, 1)
/// - Posición Y: desde +30px (abajo), cubic-bezier(0.05, 0.4, 0.5, 1)
/// - Escala: 0% → 100%, cubic-bezier(0.05, 0.4, 0.5, 1)
/// - Rotación: 60° → 0° (antihorario), cubic-bezier(0.05, 0.4, 0.5, 1)
/// - Opacidad: 0% → 100%, cubic-bezier(0.5, 0, 0.5, 1)
///
/// El wordmark usa Monomakh (fuente custom, ver pubspec.yaml) — es la
/// única excepción a Manrope, reservada al logotipo de marca, no a la UI.
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

// Timing, en ms sobre los 3000ms totales del controller — valores
// exactos exportados de Figma.
const _totalMs = 3000;

const _lockupDelayMs = 918;
const _lockupOffsetDurationMs = 1000;
const _lockupScaleDurationMs = 780;
const _lockupOpacityDurationMs = 400;

// Retraso/duración acortados respecto al export original de Figma
// (918/1000ms) — con los valores literales el cerdito tardaba
// demasiado en aparecer y el movimiento se sentía lento. Mantiene la
// forma de las curvas, solo más rápido.
const _pigDelayMs = 1300;
const _pigMoveDurationMs = 650;
const _pigOpacityDurationMs = 250;

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: HitoMotion.splashLockupAnimation,
  );

  // Lockup completo (círculo + cerdito + nombre) — retraso 918ms, cada
  // propiedad con su propia duración/curva (ver doc-comment de la clase).
  late final _lockupOffsetY = Tween<double>(begin: 20, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _lockupDelayMs / _totalMs,
        (_lockupDelayMs + _lockupOffsetDurationMs) / _totalMs,
        curve: Cubic(0.3, -1.2, 0.45, 1),
      ),
    ),
  );
  late final _lockupScale = Tween<double>(begin: 0.6, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _lockupDelayMs / _totalMs,
        (_lockupDelayMs + _lockupScaleDurationMs) / _totalMs,
        curve: Cubic(0.15, 0.52, 0.5, 1),
      ),
    ),
  );
  late final _lockupOpacity = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _lockupDelayMs / _totalMs,
        (_lockupDelayMs + _lockupOpacityDurationMs) / _totalMs,
        curve: Cubic(0.09, 0.55, 0.5, 1),
      ),
    ),
  );

  // Cerdito adentro del círculo — 5 tracks independientes, calcados de
  // los keyframes de Figma (ver doc-comment de la clase).
  static const _pigMoveInterval = Interval(
    _pigDelayMs / _totalMs,
    (_pigDelayMs + _pigMoveDurationMs) / _totalMs,
    curve: Cubic(0.05, 0.4, 0.5, 1),
  );

  late final _pigOffsetX = Tween<double>(begin: 30, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _pigDelayMs / _totalMs,
        (_pigDelayMs + _pigMoveDurationMs) / _totalMs,
        curve: Cubic(0.24, 0.08, 0.5, 1),
      ),
    ),
  );
  late final _pigOffsetY = Tween<double>(
    begin: 30,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: _pigMoveInterval));
  late final _pigScale = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: _pigMoveInterval));
  // 60° → 0°, sentido antihorario.
  late final _pigRotation = Tween<double>(
    begin: pi / 3,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: _pigMoveInterval));
  late final _pigOpacity = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        _pigDelayMs / _totalMs,
        (_pigDelayMs + _pigOpacityDurationMs) / _totalMs,
        curve: Cubic(0.5, 0, 0.5, 1),
      ),
    ),
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
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _lockupOffsetY,
                _lockupScale,
                _lockupOpacity,
              ]),
              builder: (context, child) {
                return Opacity(
                  opacity: _lockupOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _lockupOffsetY.value),
                    child: Transform.scale(
                      scale: _lockupScale.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedPigLogo(
                    offsetX: _pigOffsetX,
                    offsetY: _pigOffsetY,
                    scale: _pigScale,
                    rotation: _pigRotation,
                    opacity: _pigOpacity,
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
        ],
      ),
    );
  }
}

/// Círculo de fondo estático (entra junto con el resto del lockup) con
/// el cerdito adentro animado por separado con sus 5 tracks propios.
class _AnimatedPigLogo extends StatelessWidget {
  const _AnimatedPigLogo({
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.diameter,
  });

  final Animation<double> offsetX;
  final Animation<double> offsetY;
  final Animation<double> scale;
  final Animation<double> rotation;
  final Animation<double> opacity;
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
        animation: Listenable.merge([
          offsetX,
          offsetY,
          scale,
          rotation,
          opacity,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: opacity.value,
            child: Transform.translate(
              offset: Offset(offsetX.value, offsetY.value),
              child: Transform.rotate(
                angle: rotation.value,
                child: Transform.scale(scale: scale.value, child: child),
              ),
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
