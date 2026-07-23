import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/providers/app_providers.dart';
import 'package:serviup/domain/viewmodels/chat_viewmodel.dart';
import 'package:serviup/models/chat_model.dart';
import 'package:serviup/models/enums/chat_status.dart';
import 'package:serviup/models/enums/user_role.dart';
import 'package:serviup/models/user_model.dart';
import 'package:serviup/views/chat/chats_view.dart';

void main() {
  testWidgets('muestra la inicial del otro participante', (tester) async {
    const user = UserModel(
      id: 'provider-1',
      email: 'provider@example.com',
      role: UserRole.provider,
      name: 'Prestador',
      phone: '',
    );
    const chat = ChatModel(
      id: 'request-1_provider-1',
      requestId: 'request-1',
      clientId: 'client-1',
      providerId: 'provider-1',
      clientName: 'David',
      providerName: 'Prestador',
      status: ChatStatus.active,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
          userChatsProvider(
            user.id,
          ).overrideWith((ref) => Stream.value(const [chat])),
        ],
        child: const MaterialApp(home: ChatsView()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('David'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
