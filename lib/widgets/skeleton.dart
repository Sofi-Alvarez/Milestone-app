import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rectángulo con pulso suave — la pieza base de cualquier skeleton
/// screen. Reemplaza al spinner de pantalla completa en listas/cards
/// mientras cargan: el usuario ve la forma real del contenido en vez
/// de una pantalla en blanco.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = HitoRadius.sm,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: HitoMotion.skeletonPulse,
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (MediaQuery.of(context).disableAnimations) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = recessedColor(theme);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = MediaQuery.of(context).disableAnimations
            ? 0.7
            : 0.5 + (_controller.value * 0.3);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton con la forma de una card de lista genérica (ícono circular
/// + dos líneas de texto + monto) — cubre la mayoría de las cards del
/// producto (Registros, Metas, Presupuestos).
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HitoSpacing.md,
        vertical: HitoSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.md),
        boxShadow: cardShadow(),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: HitoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 14),
                const SizedBox(height: HitoSpacing.xs),
                SkeletonBox(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: HitoSpacing.sm),
          const SkeletonBox(width: 56, height: 14),
        ],
      ),
    );
  }
}

/// Lista de `count` skeletons de card, espaciados igual que las listas
/// reales del producto.
class SkeletonListCardGroup extends StatelessWidget {
  const SkeletonListCardGroup({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const SkeletonListCard(),
          if (i < count - 1) const SizedBox(height: HitoSpacing.sm),
        ],
      ],
    );
  }
}
