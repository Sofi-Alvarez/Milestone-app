import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../home/models/home_models.dart';

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

/// Donut "¿A dónde va mi dinero?" — tocar una porción la resalta y
/// muestra su categoría y monto en el centro; volver a tocarla (o
/// tocar afuera) vuelve al total general. La leyenda es una lista
/// inline (nombre de categoría, sin porcentaje) que se ajusta de a
/// varias por fila.
class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
  });

  final List<CategorySlice> slices;
  final String centerLabel;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _selected;

  void _selectAt(Offset localPosition, Size size) {
    final total = widget.slices.fold<double>(0, (sum, s) => sum + s.amount);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;
    final distance = vector.distance;
    // El anillo tiene 28px de grosor centrado en el radio — afuera de
    // eso el toque no selecciona nada.
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 28;
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => _selected = null);
      return;
    }
    var angle = atan2(vector.dy, vector.dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    var startAngle = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final sweep = 2 * pi * (widget.slices[i].amount / total);
      if (angle >= startAngle && angle < startAngle + sweep) {
        setState(() => _selected = _selected == i ? null : i);
        return;
      }
      startAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.slices.fold<double>(0, (sum, s) => sum + s.amount);
    final selectedSlice = _selected != null ? widget.slices[_selected!] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.xl),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.hero),
        boxShadow: cardShadow(),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: GestureDetector(
              onTapUp: (details) =>
                  _selectAt(details.localPosition, const Size(200, 200)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _DonutPainter(
                      slices: widget.slices,
                      total: total,
                      selected: _selected,
                      emptyTrackColor: recessedColor(theme),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedSlice?.label ?? widget.centerLabel,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        total == 0
                            ? 'Sin datos'
                            : formatCurrency(selectedSlice?.amount ?? total),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HitoSpacing.xl),
          Wrap(
            spacing: HitoSpacing.md,
            runSpacing: HitoSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < widget.slices.length; i++)
                InkWell(
                  onTap: () =>
                      setState(() => _selected = _selected == i ? null : i),
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: widget.slices[i].color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: HitoSpacing.xs),
                        Text(
                          widget.slices[i].label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _selected == i
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _selected == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.selected,
    required this.emptyTrackColor,
  });

  final List<CategorySlice> slices;
  final double total;
  final int? selected;

  /// Color del track cuando no hay datos — mismo `recessedColor(theme)`
  /// que ya usa el gauge de Presupuestos para su track vacío. Antes era
  /// un gris hardcodeado (`#E5E7EB`) sin versión dark mode.
  final Color emptyTrackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 28.0;

    if (total <= 0) {
      final track = Paint()
        ..color = emptyTrackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 2 * pi, false, track);
      return;
    }

    var startAngle = -pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = 2 * pi * (slice.amount / total);
      final isDimmed = selected != null && selected != i;
      final paint = Paint()
        ..color = isDimmed ? slice.color.withValues(alpha: 0.35) : slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected == i ? strokeWidth + 6 : strokeWidth;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices ||
      oldDelegate.total != total ||
      oldDelegate.selected != selected ||
      oldDelegate.emptyTrackColor != emptyTrackColor;
}
