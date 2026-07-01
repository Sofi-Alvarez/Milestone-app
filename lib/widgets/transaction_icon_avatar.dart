import 'package:flutter/material.dart';

/// Círculo de ícono de una fila de transacción — un solo tamaño (44px)
/// para que Home e Historial muestren exactamente la misma transacción
/// del mismo tamaño. Antes Home usaba un `CircleAvatar` de 40px y
/// Historial un `Container` de 44px, mismo dato con distinto tamaño.
class TransactionIconAvatar extends StatelessWidget {
  const TransactionIconAvatar({
    super.key,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 24, color: iconColor),
    );
  }
}
