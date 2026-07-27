import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/core/theme/app_dimensions.dart';
import 'package:serviup/core/theme/app_theme.dart';
import 'package:serviup/models/enums/request_status.dart';
import 'package:serviup/models/service_request_model.dart';
import 'package:serviup/widgets/request_card.dart';
import 'package:serviup/widgets/section_card.dart';

void main() {
  ServiceRequestModel buildRequest({
    RequestStatus status = RequestStatus.open,
  }) {
    return ServiceRequestModel(
      id: 'request-1',
      clientId: 'client-1',
      category: 'Plomería',
      description: 'Reparar una fuga en el lavaplatos.',
      latitude: 4.65,
      longitude: -74.05,
      address: 'Calle 1 # 2-3',
      scheduledAt: DateTime(2026, 7, 28),
      status: status,
    );
  }

  testWidgets('usa la tarjeta de servicio y conserva la interacción', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RequestCard(request: buildRequest(), onTap: () => taps++),
        ),
      ),
    );

    final section = tester.widget<SectionCard>(find.byType(SectionCard));
    expect(section.radius, AppRadius.xl);
    expect(section.padding, const EdgeInsets.all(AppSpacing.md));
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('Calle 1 # 2-3'), findsOneWidget);

    await tester.tap(find.byType(RequestCard));
    expect(taps, 1);
  });

  testWidgets('expone el estado cancelado con color y semántica de error', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: StatusChip(status: RequestStatus.cancelled)),
      ),
    );

    final context = tester.element(find.byType(StatusChip));
    final colors = Theme.of(context).colorScheme;
    final chip = tester.widget<Chip>(find.byType(Chip));

    expect(chip.backgroundColor, colors.errorContainer);
    expect(chip.labelStyle?.color, colors.onErrorContainer);
    expect(
      find.bySemanticsLabel('Estado de la solicitud: Cancelada'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('distingue visualmente estados neutrales y positivos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: StatusChip(status: RequestStatus.open)),
      ),
    );

    final context = tester.element(find.byType(StatusChip));
    final colors = Theme.of(context).colorScheme;
    var chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, colors.secondaryContainer);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: StatusChip(status: RequestStatus.completed)),
      ),
    );

    chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.labelStyle?.color, colors.primary);
    expect(chip.backgroundColor, colors.primary.withValues(alpha: 0.10));
  });
}
