/// Inverso de [formatCurrency]: acepta texto con puntos de miles y coma
/// decimal (lo que el usuario ve mientras escribe, gracias a
/// ThousandsInputFormatter) y devuelve el número real.
double parseAmountInput(String text) =>
    double.tryParse(text.trim().replaceAll('.', '').replaceAll(',', '.')) ?? 0;

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
