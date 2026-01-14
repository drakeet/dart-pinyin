import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'pinyin_db_base.dart';

class PinyinDatabaseImpl implements PinyinDatabaseBase {
  Database? _db;

  @override
  Future<void> init({String? databasePath}) async {
    if (_db != null) return;
    final dbPath = databasePath ?? await _ensureDatabasePath();
    _db = await openDatabase(dbPath, readOnly: true);
  }

  @override
  Future<String?> lookup(String table, String key) async {
    final db = _db;
    if (db == null) {
      throw StateError('PinyinDatabase is not initialized.');
    }
    final rows = await db.query(
      table,
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<String> _ensureDatabasePath() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = p.join(dbFolder, 'pinyin.db');
    final exists = await databaseExists(dbPath);
    if (exists) return dbPath;

    final bytes = await _loadAssetBytes();
    await File(dbPath).writeAsBytes(bytes, flush: true);
    return dbPath;
  }

  Future<Uint8List> _loadAssetBytes() async {
    const assetPath = 'packages/pinyin/assets/pinyin.db';
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
