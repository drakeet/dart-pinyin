import 'lru_cache.dart';
import 'phrase_converter.dart';
import 'pinyin_constants.dart';
import 'pinyin_db.dart';
import 'pinyin_resource.dart';

/// Chinese Helper.
class ChineseHelper {
  static int? minPhraseLength;
  static int? maxPhraseLength;

  static final Map<String, String> _customCharT2SMap = {};
  static final Map<String, String> _customCharS2TMap = {};
  static final Map<String, String> _customPhraseT2SMap = {};
  static final Map<String, String> _customPhraseS2TMap = {};

  static final LruCache<String, String?> _charT2SCache =
      LruCache<String, String?>(capacity: 4096);
  static final LruCache<String, String?> _charS2TCache =
      LruCache<String, String?>(capacity: 4096);
  static final LruCache<String, String?> _phraseT2SCache =
      LruCache<String, String?>(capacity: 2048);
  static final LruCache<String, String?> _phraseS2TCache =
      LruCache<String, String?>(capacity: 2048);

  static void init({String? databasePath}) =>
      PinyinDatabase.instance.init(databasePath: databasePath);

  @Deprecated('replaced by tradToSimpMap and simpToTradMap')
  static Map<String, String> get chineseMap => _customCharT2SMap;

  @Deprecated('SQLite-backed lookup only; this exposes custom additions only.')
  static Map<String, String> get charT2SMap => _customCharT2SMap;

  @Deprecated('SQLite-backed lookup only; this exposes custom additions only.')
  static Map<String, String> get charS2TMap => _customCharS2TMap;

  @Deprecated('SQLite-backed lookup only; this exposes custom additions only.')
  static Map<String, String> get phraseT2SMap => _customPhraseT2SMap;

  @Deprecated('SQLite-backed lookup only; this exposes custom additions only.')
  static Map<String, String> get phraseS2TMap => _customPhraseS2TMap;

  static bool isChineseCode(int code) =>
      (code == 0x3007) || // "〇" is also a Chinese character  〇也是汉字
      (code >= 0x3400 && code <= 0x4DBF) || // Ext+A
      (code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
      (code >= 0xF900 && code <= 0xFA6D) || // CJK Compatibility Ideographs - Part 1
      (code >= 0xFA70 && code <= 0xFAD9) || // CJK Compatibility Ideographs - Part 2
      (code >= 0x20000 && code <= 0x2A6DF) || // Ext+B
      (code >= 0x2A700 && code <= 0x2B739) || // Ext+C
      (code >= 0x2B740 && code <= 0x2B81D) || // Ext+D
      (code >= 0x2B820 && code <= 0x2CEA1) || // Ext+E
      (code >= 0x2CEB0 && code <= 0x2EBE0) || // Ext+F
      (code >= 0x2EBF0 && code <= 0x2EE5D) || // Ext+I
      (code >= 0x2F800 && code <= 0x2FA1F) || // CJK Compatibility Supplement
      (code >= 0x30000 && code <= 0x3134A) || // Ext+G
      (code >= 0x31350 && code <= 0x323AF); // Ext+H

  /// 判断某个字符是否为汉字
  /// @return 是汉字返回true，否则返回false
  static bool isChinese(String c) {
    try {
      return isChineseCode(c.runes.first);
    } catch (e) {
      return false;
    }
    // a better workaround:
    // return isChineseCode(c.runes.firstOrNull ?? -1);
    // while avoid using firstOrNull for compatible with Dart 2.
  }

  /// 判断某个字符是否为繁体字
  /// @param c 需要判断的字符
  /// @return 是繁体字返回true，否则返回false
  static bool isSimplifiedChinese(String c) {
    final custom = _customCharS2TMap.containsKey(c);
    if (custom) return true;
    final value = _lookupCharS2T(c);
    return value != null;
  }

  /// 判断某个字符是否为繁体字
  /// @param c 需要判断的字符
  /// @return 是繁体字返回true，否则返回false
  static bool isTraditionalChinese(String c) {
    final custom = _customCharT2SMap.containsKey(c);
    if (custom) return true;
    final value = _lookupCharT2S(c);
    return value != null;
  }

  /// 判断字符串中是否包含中文
  /// @param str 字符串
  /// @return 包含汉字返回true，否则返回false
  static bool containsChinese(String str) {
    final runes = str.runes;
    for (int i = 0, len = runes.length; i < len; i++) {
      if (isChinese(str[i])) {
        return true;
      }
    }
    return false;
  }

  /// 将单个繁体字转换为简体字
  /// @param c 需要转换的繁体字
  /// @return 转换后的简体字
  static String convertCharToSimplifiedChinese(String c) =>
      _customCharT2SMap[c] ?? _lookupCharT2S(c) ?? c;

  /// 将单个简体字转换为繁体字
  /// @param c 需要转换的简体字
  /// @return 转换后的繁体字
  static String convertCharToTraditionalChinese(String c) =>
      _customCharS2TMap[c] ?? _lookupCharS2T(c) ?? c;

  /// 将繁体字转换为简体字
  /// @param str 需要转换的繁体字
  /// @return 转换后的简体字
  static String convertToSimplifiedChinese(String str) =>
      _stringConvert(str, _lookupPhraseT2S, convertCharToSimplifiedChinese,
          minPhraseLengthT2S, maxPhraseLengthT2S);

  /// 将简体字转换为繁体字
  /// @param str 需要转换的简体字
  /// @return 转换后的繁体字
  static String convertToTraditionalChinese(String str) =>
      _stringConvert(str, _lookupPhraseS2T, convertCharToTraditionalChinese,
          minPhraseLengthS2T, maxPhraseLengthS2T);

  static String _stringConvert(
    String str,
    String? Function(String) phraseLookup,
    String Function(String) singleCharConvert,
    int min,
    int max,
  ) {
    StringBuffer sb = StringBuffer();
    final runes = str.runes.toList();
    int i = 0;
    while (i < runes.length) {
      String subStr = String.fromCharCodes(runes.sublist(i));
      String _char = String.fromCharCode(runes[i]);
      bool isHan = ChineseHelper.isChinese(_char);

      PhraseConvert? node = stConvertForPhrase(subStr, phraseLookup, min, max);
      if (node == null) {
        if (isHan) {
          sb.write(singleCharConvert.call(String.fromCharCode(runes[i])));
        } else {
          sb.write(_char);
        }
        i++;
      } else {
        sb.write(node.result?.trim());
        i += node.word!.runes.length;
      }
    }

    return sb.toString();
  }

  /// 词组转换
  /// @param str 需要转换的字符串
  /// @param dict 转换词典
  /// @return 转换结果
  static PhraseConvert? stConvertForPhrase(
    String str,
    String? Function(String) phraseLookup,
    int min,
    int max,
  ) {
    final runes = str.runes.toList();
    final minLen = minPhraseLength ?? min;
    final maxLen = maxPhraseLength ?? max;
    if (runes.length < minLen) return null;
    for (int end = (runes.length < maxLen ? runes.length : maxLen); end >= minLen; end--) {
      String subStr = String.fromCharCodes(runes.sublist(0, end));
      String? result = phraseLookup(subStr);
      if (result != null && result.isNotEmpty) {
        return PhraseConvert(word: subStr, result: result);
      }
    }
    return null;
  }

  /// 添加繁体字字典
  static void addSimpToTradMap(Map<String, String> map) {
    _customCharS2TMap.addAll(map);
  }

  /// 添加简体字字典
  static void addTradToSimpMap(Map<String, String> map) {
    _customCharT2SMap.addAll(map);
  }

  /// 添加繁体字字典
  @Deprecated('Replaced by addSimpToTradMap and addTradToSimpMap')
  static void addChineseDict(List<String> list) {
    final map = PinyinResource.getResource(list);
    addTradToSimpMap(map);
    addSimpToTradMap(map.map((key, value) => MapEntry(value, key)));
  }

  static String? _lookupCharT2S(String key) {
    if (_charT2SCache.containsKey(key)) {
      return _charT2SCache.get(key);
    }
    final value = PinyinDatabase.instance.lookup(tableTradToSimp, key);
    _charT2SCache.put(key, value);
    return value;
  }

  static String? _lookupCharS2T(String key) {
    if (_charS2TCache.containsKey(key)) {
      return _charS2TCache.get(key);
    }
    final value = PinyinDatabase.instance.lookup(tableSimpToTrad, key);
    _charS2TCache.put(key, value);
    return value;
  }

  static String? _lookupPhraseT2S(String key) {
    final custom = _customPhraseT2SMap[key];
    if (custom != null) return custom;
    if (_phraseT2SCache.containsKey(key)) {
      return _phraseT2SCache.get(key);
    }
    final value = PinyinDatabase.instance.lookup(tablePhraseT2S, key);
    _phraseT2SCache.put(key, value);
    return value;
  }

  static String? _lookupPhraseS2T(String key) {
    final custom = _customPhraseS2TMap[key];
    if (custom != null) return custom;
    if (_phraseS2TCache.containsKey(key)) {
      return _phraseS2TCache.get(key);
    }
    final value = PinyinDatabase.instance.lookup(tablePhraseS2T, key);
    _phraseS2TCache.put(key, value);
    return value;
  }
}
