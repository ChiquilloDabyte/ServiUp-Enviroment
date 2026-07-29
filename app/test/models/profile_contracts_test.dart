import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/models/profile_update.dart';
import 'package:serviup/models/review_model.dart';

void main() {
  test('ProfileUpdate solo serializa campos editables', () {
    const update = ProfileUpdate(
      name: '  Prestador  ',
      serviceCategories: ['Plomería'],
      photoUrl: 'https://example.com/avatar.jpg',
      latitude: 4.71,
      longitude: -74.07,
    );

    final data = update.toFirestore();

    expect(data['name'], 'Prestador');
    expect(data, isNot(contains('phone')));
    expect(data, isNot(contains('phoneVerifiedAt')));
    expect(data['profileComplete'], isTrue);
    expect(data, isNot(contains('role')));
    expect(data, isNot(contains('rating')));
    expect(data, isNot(contains('ratingCount')));
  });

  test('ReviewModel conserva el contrato reservado', () {
    const review = ReviewModel(
      requestId: 'request-1',
      clientId: 'client-1',
      providerId: 'provider-1',
      rating: 5,
      comment: ' Excelente servicio ',
    );

    final data = review.toFirestore();

    expect(data['requestId'], 'request-1');
    expect(data['rating'], 5);
    expect(data['comment'], 'Excelente servicio');
    expect(data.keys, containsAll(['clientId', 'providerId', 'createdAt']));
  });
}
