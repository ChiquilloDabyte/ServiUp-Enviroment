import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/constants/app_constants.dart';
import 'package:serviup/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme renders ServiUp branding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text(AppConstants.appName)),
        ),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
