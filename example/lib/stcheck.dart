import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:pinyin/pinyin.dart';

Future<void> main() async {
  await ChineseHelper.init();
  var path = 'example/simp';
  new File(path)
      .openRead()
      .map(utf8.decode)
      .transform(new LineSplitter())
      .forEach((l) async {
        if (await ChineseHelper.convertToSimplifiedChinese(l) != l) {
          print(l);
        }
  });
}
