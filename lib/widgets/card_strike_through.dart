import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tacha una card entera con un trazo tipo pincel (no una línea recta) y
/// atenúa levemente el contenido — el gesto de "esto ya está resuelto,
/// no tengo que pensar más en esto". Es un componente puramente
/// emocional, no informativo: ver casos de uso permitidos/prohibidos
/// en la skill de Interacción (solo pagos programados resueltos,
/// checklists y recordatorios completados — nunca gastos, ingresos,
/// metas o alertas).
///
/// Al terminar de dibujarse, el estado tachado queda visible
/// [holdDuration] antes de que quien lo use dispare lo que sigue — si
/// el usuario no llega a verlo, se pierde el efecto de alivio.
class CardStrikeThrough extends StatefulWidget {
  const CardStrikeThrough({
    super.key,
    required this.trigger,
    required this.child,
  });

  final bool trigger;
  final Widget child;

  // Un trazo real es un gesto rápido de la muñeca, no un progreso
  // parejo — sale de golpe y frena en seco al final. 650ms lineales se
  // sentían como una barra de carga, no como un tachón.
  final Duration drawDuration = HitoMotion.strikeThrough;

  @override
  State<CardStrikeThrough> createState() => _CardStrikeThroughState();
}

class _CardStrikeThroughState extends State<CardStrikeThrough>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.drawDuration,
  );
  // Arranca rápido y frena en seco — la curva es lo que hace que se
  // lea como un trazo de una sola pasada en vez de un progreso lineal.
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutQuart,
  );
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      if (widget.trigger) _play();
    }
  }

  @override
  void didUpdateWidget(covariant CardStrikeThrough oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) _play();
  }

  void _play() {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final progress = _curve.value;
        return Stack(
          children: [
            Opacity(opacity: 1 - (progress * 0.35), child: widget.child),
            if (progress > 0)
              Positioned.fill(
                child: CustomPaint(
                  // Azul más oscuro de la paleta (mismo tono que el fondo
                  // del splash) — el trazo tiene que leerse marcado, no
                  // difuminarse con el color neutro del texto.
                  painter: _BrushStrikePainter(
                    progress: progress,
                    color: HitoColors.splashBackground,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dibuja un trazo ondulado con textura (tres pasadas de distinto
/// grosor/opacidad levemente desplazadas) para que se lea como pincel,
/// no como regla — inspirado en el pincel "Noir" de Figma.
class _BrushStrikePainter extends CustomPainter {
  _BrushStrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final points = [
      Offset(w * 0.02, midY + h * 0.08),
      Offset(w * 0.22, midY - h * 0.11),
      Offset(w * 0.48, midY + h * 0.09),
      Offset(w * 0.74, midY - h * 0.07),
      Offset(w * 0.98, midY + h * 0.05),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  // Keyframes de presión a lo largo del trazo (no del tiempo): 25% al
  // arrancar, sube a 45%, baja a 40%, sube a 60%, y llega al 100% al
  // final — así el grosor varía como la presión real de una pincelada
  // en vez de quedar parejo de punta a punta.
  static const _pressureKeyframes = [0.25, 0.45, 0.40, 0.60, 1.00];

  double _pressureAt(double t) {
    final segments = _pressureKeyframes.length - 1;
    final scaled = t.clamp(0.0, 1.0) * segments;
    final idx = scaled.floor().clamp(0, segments - 1);
    final localT = scaled - idx;
    final a = _pressureKeyframes[idx];
    final b = _pressureKeyframes[idx + 1];
    return a + (b - a) * localT;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final metrics = _buildPath(size).computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final revealedLength = metric.length * progress.clamp(0.0, 1.0);
    if (revealedLength <= 0) return;

    // La presión se calcula sobre la posición en el trazo COMPLETO (no
    // sobre lo revelado), para que el grosor ya varíe espacialmente
    // mientras se va dibujando, no solo al terminar.
    const steps = 40;
    final stepLength = revealedLength / steps;

    void drawPass(double dy, double baseWidthFactor, double alpha) {
      canvas.save();
      canvas.translate(0, dy);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < steps; i++) {
        final start = i * stepLength;
        final end = (start + stepLength).clamp(0.0, revealedLength);
        if (end <= start) continue;
        final segment = metric.extractPath(start, end);
        final tMid = ((start + end) / 2) / metric.length;
        paint.strokeWidth = size.height * baseWidthFactor * _pressureAt(tMid);
        canvas.drawPath(segment, paint);
      }
      canvas.restore();
    }

    drawPass(1.5, 0.035, 0.3);
    drawPass(-1.5, 0.03, 0.22);
    drawPass(0, 0.05, 1);
  }

  @override
  bool shouldRepaint(covariant _BrushStrikePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
