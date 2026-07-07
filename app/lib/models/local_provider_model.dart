import 'package:isar/isar.dart';

part 'local_provider_model.g.dart';

@collection
class LocalProvider {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String firebaseId;

  late String name;
  late String phone;
  late List<String> categories;
  late DateTime lastSyncedAt;
}
