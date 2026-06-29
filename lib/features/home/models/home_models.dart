/// Meta de ahorro mostrada en el home. `target == null` representa el
/// estado "sin meta definida" (primer ingreso, sin actividad todavía).
class SavingsGoal {
  const SavingsGoal({required this.title, required this.current, this.target});

  final String title;
  final double current;
  final double? target;

  bool get isActive => target != null && target! > 0;

  double get progress {
    if (!isActive) return 0;
    return (current / target!).clamp(0, 1);
  }
}

class Movement {
  const Movement({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isPositive = true,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive;
}

/// Formato simple "$1.800.400,00" (separador de miles '.', decimales ',').
String formatCurrency(double value) {
  final isNegative = value < 0;
  final cents = (value.abs() * 100).round();
  final wholePart = cents ~/ 100;
  final decimalPart = (cents % 100).toString().padLeft(2, '0');

  final wholeDigits = wholePart.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < wholeDigits.length; i++) {
    if (i > 0 && (wholeDigits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(wholeDigits[i]);
  }

  return '${isNegative ? '-' : ''}\$$buffer,$decimalPart';
}
