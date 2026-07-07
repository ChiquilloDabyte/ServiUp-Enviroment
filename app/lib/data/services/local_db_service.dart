import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logger/app_logger.dart';
import '../../models/local_provider_model.dart';

class LocalDbService {
  LocalDbService();

  Isar? _isar;

  Future<Isar> get database async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalProviderSchema],
      directory: dir.path,
    );
    AppLogger.info('Isar database opened');
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
