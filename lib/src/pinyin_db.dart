import 'pinyin_db_base.dart';
import 'pinyin_db_stub.dart'
    if (dart.library.ui) 'pinyin_db_flutter.dart'
    if (dart.library.io) 'pinyin_db_io.dart';

class PinyinDatabase {
  PinyinDatabase._(this._impl);

  static final PinyinDatabase _instance = PinyinDatabase._(PinyinDatabaseImpl());

  final PinyinDatabaseBase _impl;
  Future<void>? _initFuture;

  static PinyinDatabase get instance => _instance;

  Future<void> init({String? databasePath}) {
    _initFuture ??= _impl.init(databasePath: databasePath);
    return _initFuture!;
  }

  Future<String?> lookup(String table, String key) async {
    await init();
    return _impl.lookup(table, key);
  }

  Future<void> close() => _impl.close();
}
