import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo de Milestone: círculo de fondo + el trazo del cerdito,
/// recoloreado según el tema (claro/oscuro) en vez de usar los
/// colores fijos del export original de Figma.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.diameter = 64,
    this.iconScale = 0.62,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double diameter;
  final double iconScale;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = foregroundColor ?? scheme.onPrimaryContainer;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/branding/pig_mark.svg',
        width: diameter * iconScale,
        height: diameter * iconScale,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
    );
  }
}
