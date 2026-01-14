import 'dart:collection';

import 'pinyin_db.dart';

/// Pinyin Resource.
class PinyinResource {
  static void init({String? databasePath}) =>
      PinyinDatabase.instance.init(databasePath: databasePath);

  /// get Resource.
  @Deprecated('No longer needed.')
  static Map<String, String> getResource(List<String> list) {
    Map<String, String> map = HashMap();
    List<MapEntry<String, String>> mapEntryList = [];
    for (int i = 0, length = list.length; i < length; i++) {
      List<String> tokens = list[i].trim().split('=');
      MapEntry<String, String> mapEntry = MapEntry(tokens[0], tokens[1]);
      mapEntryList.add(mapEntry);
    }
    map.addEntries(mapEntryList);
    return map;
  }
}
