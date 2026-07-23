import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/data/repositories/chat_repository.dart';
import 'package:serviup/models/chat_model.dart';
import 'package:serviup/models/enums/chat_status.dart';
import 'package:serviup/models/enums/offer_status.dart';

void main() {
  group('ChatRepository.chatIdFor', () {
    test('genera el mismo chat para una solicitud y un proveedor', () {
      expect(
        ChatRepository.chatIdFor('request-1', 'provider-2'),
        'request-1_provider-2',
      );
    });

    test('separa conversaciones de proveedores diferentes', () {
      expect(
        ChatRepository.chatIdFor('request-1', 'provider-1'),
        isNot(ChatRepository.chatIdFor('request-1', 'provider-2')),
      );
    });
  });

  group('ChatModel', () {
    const chat = ChatModel(
      id: 'chat-1',
      requestId: 'request-1',
      clientId: 'client-1',
      providerId: 'provider-1',
      clientName: 'Cliente',
      providerName: 'Prestador',
      status: ChatStatus.active,
      unreadByClient: 2,
      unreadByProvider: 3,
    );

    test('resuelve participantes y contadores', () {
      expect(chat.containsParticipant('client-1'), isTrue);
      expect(chat.containsParticipant('provider-1'), isTrue);
      expect(chat.containsParticipant('other'), isFalse);
      expect(chat.unreadFor('client-1'), 2);
      expect(chat.unreadFor('provider-1'), 3);
    });

    test('muestra el nombre de la contraparte', () {
      expect(chat.otherParticipantName('client-1'), 'Prestador');
      expect(chat.otherParticipantName('provider-1'), 'Cliente');
    });
  });

  test('OfferStatus reconoce propuestas reemplazadas', () {
    expect(OfferStatus.fromString('superseded'), OfferStatus.superseded);
    expect(OfferStatus.superseded.label, 'Reemplazada');
  });
}
