import 'package:flutter/services.dart';

/// Aplica el separador de miles ('.') en vivo mientras el usuario
/// escribe un monto — antes solo se veía formateado al confirmar, lo
/// que hacía difícil notar si el número tenía un cero de más o de
/// menos. La coma sigue siendo el separador decimal.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final raw = newValue.text.replaceAll('.', '');
    final commaIndex = raw.indexOf(',');
    final hasComma = commaIndex != -1;
    final intPart = (hasComma ? raw.substring(0, commaIndex) : raw).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final decPart = hasComma
        ? raw.substring(commaIndex + 1).replaceAll(RegExp(r'[^0-9]'), '')
        : '';

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    var formatted = buffer.toString();
    if (hasComma) formatted = '$formatted,$decPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
