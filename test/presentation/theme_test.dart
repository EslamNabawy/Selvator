import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light theme avoids pure white primary surfaces', () {
    final theme = WiselyTheme.light();

    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.cardTheme.color, isNot(Colors.white));
    expect(theme.inputDecorationTheme.fillColor, isNot(Colors.white));
    expect(theme.colorScheme.surfaceContainerLowest, isNot(Colors.white));
  });
}
