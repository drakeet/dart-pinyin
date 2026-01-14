abstract class PinyinDatabaseBase {
  Future<void> init({String? databasePath});
  Future<String?> lookup(String table, String key);
  Future<void> close();
}
