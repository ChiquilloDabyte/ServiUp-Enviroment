import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_dimensions.dart';
import 'package:serviup/widgets/responsive_content.dart';

void main() {
  testWidgets('uses 20px mobile margins', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(child: SizedBox.expand(key: Key('content'))),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key('content'))).dx, 20);
  });

  testWidgets('caps desktop content at 1200px', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(child: SizedBox.expand(key: Key('content'))),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('content'))).width,
      AppBreakpoints.maxContentWidth - (AppSpacing.md * 2),
    );
  });

  testWidgets('supports centered content for splash surfaces', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(
            alignment: Alignment.center,
            padding: EdgeInsets.zero,
            child: SizedBox(
              key: Key('centered-content'),
              width: 100,
              height: 100,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('centered-content'))),
      const Offset(150, 350),
    );
  });
}
