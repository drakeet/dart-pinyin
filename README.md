# dart-pinyin

将中文转换为拼音与注音，支持多音字、词组歧义消解，以及简繁转换。  
灵感来自 Java 库 [jpinyin](https://github.com/SilenceDut/jpinyin)。

## 功能特性

- 完整准确的字典与词组库
- 多种拼音格式：带声调、声调数字、不带声调、首字母
- 多音字支持（词语、成语、地名）
- 简体 ↔ 繁体转换
- 支持用户自定义字典
- 注音（Bopomofo）支持，参考 [python-zhuyin](https://github.com/rku1999/python-zhuyin)

## 存储重构（SQLite + 缓存）

- 字典存放于 `assets/pinyin.db`，不再使用超大的 Dart map
- 运行时使用 `sqlite3` 查询，并带 LRU 内存缓存
- API 默认同步，若需要异步可由使用方自行封装

## 安装

```yaml
dependencies:
  pinyin: ^3.3.0
```

## 快速开始

```dart
import 'package:pinyin/pinyin.dart';

void main() {
  PinyinHelper.init();

  const text = '天府广场';

  PinyinHelper.getShortPinyin(text); // tfgc
  PinyinHelper.getFirstWordPinyin(text); // tian
  PinyinHelper.getPinyin(text); // han yu pin yin fang an
  PinyinHelper.getPinyin(
    text,
    separator: ' ',
    format: PinyinFormat.WITHOUT_TONE,
  );

  PinyinHelper.getPinyinE(
    text,
    separator: ' ',
    defPinyin: '#',
    format: PinyinFormat.WITHOUT_TONE,
  );
}
```

## 自定义字典

```dart
PinyinHelper.addPinyinDict(['耀=yào', '老=lǎo']);
PinyinHelper.addMultiPinyinDict(['奇偶=jī,ǒu', '成都=chéng,dū']);
ChineseHelper.addChineseDict(['倆=俩', '們=们']);
```

## 简繁转换

```dart
ChineseHelper.convertToSimplifiedChinese('繁體字');
ChineseHelper.convertToTraditionalChinese('简体字');
```

## 注音

```dart
ZhuyinHelper.getZhuyin('汉语拼音');
ZhuyinHelper.getZhuyin('汉语拼音', format: PinyinFormat.WITH_TONE_MARK);
ZhuyinHelper.getZhuyin('汉语拼音', format: PinyinFormat.WITH_TONE_NUMBER);
```

## SQLite 资源生成

在本地从原始数据生成 `assets/pinyin.db`：

```bash
dart run dev/tools/build_sqlite.dart
```

## 截图

![](https://s1.ax1x.com/2020/11/05/B2fwQO.gif)

## 更新日志

请查看 [CHANGELOG.md](CHANGELOG.md)。

## 致谢

- Unihan: https://www.unicode.org/Public/15.0.0/ucd/Unihan.zip
- Wiktionary
- 汉典: https://www.zdic.net/
- mozillazg/pinyin-data: https://github.com/mozillazg/pinyin-data/blob/master/pinyin.txt
- 原作者: @Sky24n, @tanghongliang, @duwen, @thl (flutterchina)
