import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/models/enums/offer_status.dart';
import 'package:serviup/models/enums/request_status.dart';
import 'package:serviup/models/enums/user_role.dart';

void main() {
  group('UserRole', () {
    test('fromString returns client by default', () {
      expect(UserRole.fromString('unknown'), UserRole.client);
    });

    test('provider label is correct', () {
      expect(UserRole.provider.label, 'Prestador');
    });
  });

  group('RequestStatus', () {
    test('open is active', () {
      expect(RequestStatus.open.isActive, isTrue);
    });

    test('completed is not active', () {
      expect(RequestStatus.completed.isActive, isFalse);
    });
  });

  group('OfferStatus', () {
    test('fromString parses accepted', () {
      expect(OfferStatus.fromString('accepted'), OfferStatus.accepted);
    });
  });
}
