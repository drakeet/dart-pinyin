import 'pinyin_db_base.dart';

class PinyinDatabaseImpl implements PinyinDatabaseBase {
  @override
  Future<void> init({String? databasePath}) {
    throw UnsupportedError('SQLite backend is not available on this platform.');
  }

  @override
  Future<String?> lookup(String table, String key) {
    throw UnsupportedError('SQLite backend is not available on this platform.');
  }

  @override
  Future<void> close() async {}
}
