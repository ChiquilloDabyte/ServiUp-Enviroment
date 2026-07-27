import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_colors.dart';
import 'package:serviup/core/theme/app_theme.dart';

void main() {
  group('Organic Utility theme', () {
    test('uses the semantic colors from DESIGN.md', () {
      final theme = AppTheme.lightTheme;

      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.primaryContainer, AppColors.primaryContainer);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('uses Manrope and the documented type scale', () {
      final theme = AppTheme.lightTheme;

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
      expect(theme.textTheme.bodyMedium?.fontSize, 16);
      expect(theme.textTheme.headlineLarge?.fontSize, 32);
      expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.labelLarge?.fontSize, 14);
    });

    testWidgets('primary buttons keep the minimum accessible height', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: FilledButton(
              onPressed: () {},
              child: const Text('Continuar'),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FilledButton)).height, 48);
    });
  });
}
