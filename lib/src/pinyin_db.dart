import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class PinyinDatabase {
  PinyinDatabase._();

  static final PinyinDatabase _instance = PinyinDatabase._();
  Database? _db;

  static PinyinDatabase get instance => _instance;

  void init({String? databasePath}) {
    if (_db != null) return;
    final dbPath = databasePath ?? 'assets/pinyin.db';
    if (!File(dbPath).existsSync()) {
      throw StateError('Database file not found: $dbPath');
    }
    _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  }

  String? lookup(String table, String key) {
    final db = _db;
    if (db == null) {
      throw StateError('PinyinDatabase is not initialized.');
    }
    final result = db.select(
      'select value from $table where key = ? limit 1',
      [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  void close() {
    _db?.dispose();
    _db = null;
  }
}
