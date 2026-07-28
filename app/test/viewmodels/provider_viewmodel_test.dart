import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/viewmodels/provider_viewmodel.dart';
import 'package:serviup/models/provider_public_profile_model.dart';

void main() {
  const provider = ProviderPublicProfileModel(
    id: 'provider-1',
    name: 'Ana Torres',
    phone: '3001234567',
    serviceCategories: ['Plomería', 'Reparaciones'],
    rating: 4.8,
    ratingCount: 12,
  );

  test(
    'filtra prestadores por nombre y categoría sin distinguir mayúsculas',
    () {
      expect(providerMatchesSearch(provider, query: 'ana'), isTrue);
      expect(providerMatchesSearch(provider, query: 'PLOMERÍA'), isTrue);
      expect(providerMatchesSearch(provider, query: 'electricidad'), isFalse);
    },
  );

  test('combina el filtro de categoría con el texto de búsqueda', () {
    expect(
      providerMatchesSearch(provider, query: 'torres', category: 'Plomería'),
      isTrue,
    );
    expect(
      providerMatchesSearch(
        provider,
        query: 'torres',
        category: 'Electricidad',
      ),
      isFalse,
    );
  });
}
