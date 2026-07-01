import 'package:flutter/material.dart';

/// Anillo de progreso circular de un solo valor — reemplaza
/// `GoalProgressDonut` (Metas) y el `CustomPainter` a medida que tenía
/// Presupuestos (`_GaugePainter`), que dibujaban exactamente lo mismo
/// (mismo grosor de trazo, mismo ángulo de inicio) por caminos
/// distintos: uno con `CircularProgressIndicator`, el otro pintando el
/// arco a mano. Acá los dos casos usan el widget nativo de Flutter, que
/// ya resuelve lo que el `CustomPainter` reimplementaba.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 160,
    this.strokeWidth = 14,
    this.color,
    this.trackColor,
    this.center,
  });

  /// 0.0 a 1.0. Valores fuera de rango se clampean.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;

  /// Contenido centrado dentro del anillo (ej. el porcentaje).
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor:
                  trackColor ?? theme.colorScheme.surfaceContainerHighest,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}
