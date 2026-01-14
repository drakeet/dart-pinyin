import 'dart:convert';
import 'dart:io';

import 'package:pinyin/data/phrase_map.dart';
import 'package:pinyin/data/phrase_simp_to_trad.dart';
import 'package:pinyin/data/phrase_trad_to_simp.dart';
import 'package:pinyin/data/pinyin_map.dart';
import 'package:pinyin/data/simp_to_trad_map.dart';
import 'package:pinyin/data/trad_to_simp_map.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:pinyin/src/pinyin_constants.dart';

const String outputPath = 'assets/pinyin.db';

void main() {
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  if (outputFile.existsSync()) {
    outputFile.deleteSync();
  }

  final db = sqlite3.open(outputPath);
  db.execute('pragma journal_mode = off');
  db.execute('pragma synchronous = off');

  _createTables(db);
  _insertJson(db, tablePinyin, pinyinJson);
  _insertJson(db, tablePhrasePinyin, phrasePinyin);
  _insertJson(db, tableSimpToTrad, simpToTradJson);
  _insertJson(db, tableTradToSimp, tradToSimpJson);
  _insertJson(db, tablePhraseS2T, phraseS2TJson);
  _insertJson(db, tablePhraseT2S, phraseT2SJson);

  db.dispose();
  print('SQLite database generated at $outputPath');
}

void _createTables(Database db) {
  db.execute('create table $tablePinyin (key text primary key, value text not null)');
  db.execute('create table $tablePhrasePinyin (key text primary key, value text not null)');
  db.execute('create table $tableSimpToTrad (key text primary key, value text not null)');
  db.execute('create table $tableTradToSimp (key text primary key, value text not null)');
  db.execute('create table $tablePhraseS2T (key text primary key, value text not null)');
  db.execute('create table $tablePhraseT2S (key text primary key, value text not null)');
}

void _insertJson(Database db, String table, String jsonString) {
  final decoded = json.decode(jsonString) as Map<String, dynamic>;
  final stmt = db.prepare('insert into $table (key, value) values (?, ?)');
  db.execute('begin');
  for (final entry in decoded.entries) {
    stmt.execute([entry.key, entry.value]);
  }
  db.execute('commit');
  stmt.dispose();
}
