import 'package:flutter_test/flutter_test.dart';
import 'package:hito/theme/app_theme.dart';

void main() {
  test('HitoTheme builds valid light and dark ThemeData', () {
    final light = HitoTheme.light();
    final dark = HitoTheme.dark();

    expect(light.colorScheme.primary, HitoColors.primaryLight);
    expect(dark.colorScheme.primary, HitoColors.primaryDark);
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
  });
}
