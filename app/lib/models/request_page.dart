import 'service_request_model.dart';

class RequestPageCursor {
  const RequestPageCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;
}

class RequestPage {
  const RequestPage({required this.items, this.nextCursor});

  final List<ServiceRequestModel> items;
  final RequestPageCursor? nextCursor;
}
