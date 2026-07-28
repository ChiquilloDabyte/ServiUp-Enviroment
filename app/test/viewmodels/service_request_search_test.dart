import 'package:flutter_test/flutter_test.dart';
import 'package:serviup/domain/viewmodels/service_request_viewmodel.dart';
import 'package:serviup/models/enums/request_status.dart';
import 'package:serviup/models/service_request_model.dart';

void main() {
  final request = ServiceRequestModel(
    id: 'request-1',
    clientId: 'client-1',
    category: 'Electricidad',
    description: 'Instalar una lámpara en la sala',
    latitude: 4.65,
    longitude: -74.05,
    address: 'Calle 10 # 20-30',
    scheduledAt: DateTime(2026, 7, 28),
    status: RequestStatus.open,
  );

  test('filtra solicitudes por categoría, descripción y dirección', () {
    expect(requestMatchesSearch(request, 'electricidad'), isTrue);
    expect(requestMatchesSearch(request, 'LÁMPARA'), isTrue);
    expect(requestMatchesSearch(request, 'calle 10'), isTrue);
    expect(requestMatchesSearch(request, 'plomería'), isFalse);
  });
}
