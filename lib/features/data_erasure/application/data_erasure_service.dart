import '../../../core/database/app_database.dart';

class DataErasureService {
  const DataErasureService(this._database);

  final AppDatabase _database;

  Future<void> eraseAllLocalData() async {
    await _database.transaction(() async {
      // Delete explicitly in dependency order instead of relying only
      // on foreign-key cascades.
      await _database.delete(_database.regretCheckins).go();
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.profiles).go();
    });
  }
}
