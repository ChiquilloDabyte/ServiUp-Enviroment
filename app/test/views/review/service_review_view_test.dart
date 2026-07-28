import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/views/review/service_review_view.dart';

void main() {
  testWidgets('exige estrellas y entrega la calificación con comentario', (
    tester,
  ) async {
    int? submittedRating;
    String? submittedComment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceReviewForm(
            saving: false,
            onSubmit: (rating, comment) async {
              submittedRating = rating;
              submittedComment = comment;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enviar calificación'));
    await tester.pump();
    expect(
      find.text('Selecciona una calificación antes de continuar.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('5 estrellas'));
    await tester.enterText(find.byType(TextField), 'Excelente atención');
    await tester.tap(find.text('Enviar calificación'));
    await tester.pump();

    expect(submittedRating, 5);
    expect(submittedComment, 'Excelente atención');
  });
}
