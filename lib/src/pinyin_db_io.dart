import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'pinyin_db_base.dart';

class PinyinDatabaseImpl implements PinyinDatabaseBase {
  Database? _db;

  @override
  Future<void> init({String? databasePath}) async {
    if (_db != null) return;
    final dbPath = databasePath ?? 'assets/pinyin.db';
    if (!File(dbPath).existsSync()) {
      throw StateError('Database file not found: $dbPath');
    }
    _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  }

  @override
  Future<String?> lookup(String table, String key) async {
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

  @override
  Future<void> close() async {
    _db?.dispose();
    _db = null;
  }
}
