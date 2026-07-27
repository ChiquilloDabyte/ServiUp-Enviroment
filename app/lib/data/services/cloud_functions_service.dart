import 'package:cloud_functions/cloud_functions.dart';

import '../../core/errors/app_exception.dart';

class CloudFunctionsService {
  CloudFunctionsService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      if (value is Map) return Map<String, dynamic>.from(value);
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw RepositoryException(
        error.message ?? 'No se pudo completar la operaciÃ³n.',
        code: error.code,
      );
    }
  }
}
