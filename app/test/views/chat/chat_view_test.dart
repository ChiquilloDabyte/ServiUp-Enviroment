import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/chat_viewmodel.dart';
import 'package:serviup/domain/viewmodels/offer_viewmodel.dart';
import 'package:serviup/models/chat_model.dart';
import 'package:serviup/models/enums/chat_status.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/user_model.dart';
import 'package:serviup/views/chat/chat_view.dart';

void main() {
  testWidgets('un chat cerrado se muestra en modo solo lectura', (
    tester,
  ) async {
    const chatId = 'request-1_provider-1';
    const user = UserModel(
      id: 'client-1',
      email: 'client@example.com',
      role: UserRole.client,
      name: 'Cliente',
      phone: '',
    );
    const chat = ChatModel(
      id: chatId,
      requestId: 'request-1',
      clientId: 'client-1',
      providerId: 'provider-1',
      status: ChatStatus.readOnly,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
          chatDetailProvider(chatId).overrideWith((ref) => Stream.value(chat)),
          chatMessagePageProvider((
            chatId: chatId,
            limit: 50,
          )).overrideWith((ref) => Stream.value(const [])),
          chatOffersProvider(
            chatId,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ChatView(chatId: chatId)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('solo para lectura'), findsOneWidget);
    expect(find.byTooltip('Enviar'), findsNothing);
    expect(find.byTooltip('Enviar imagen'), findsNothing);
  });

  testWidgets('cierra el diálogo de propuesta sin reutilizar controladores', (
    tester,
  ) async {
    const chatId = 'request-1_provider-1';
    const user = UserModel(
      id: 'client-1',
      email: 'client@example.com',
      role: UserRole.client,
      name: 'Cliente',
      phone: '',
    );
    const chat = ChatModel(
      id: chatId,
      requestId: 'request-1',
      clientId: 'client-1',
      providerId: 'provider-1',
      status: ChatStatus.active,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
          chatDetailProvider(chatId).overrideWith((ref) => Stream.value(chat)),
          chatMessagePageProvider((
            chatId: chatId,
            limit: 50,
          )).overrideWith((ref) => Stream.value(const [])),
          chatOffersProvider(
            chatId,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ChatView(chatId: chatId)),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Nueva propuesta'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva propuesta'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva propuesta'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
