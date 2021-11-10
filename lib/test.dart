import 'dart:convert';

import 'package:hive/hive.dart';

void main() async {
  Hive.init('testData/');
  final box = await Hive.openBox('box');
  box.clear();
  box.put(
    '1',
    jsonEncode({
      'value': 'uselessString',
      'values': [1, 24, 5],
      'dateTime': DateTime.now().toIso8601String(),
    }),
  );
  Map<String, dynamic> value = jsonDecode(box.get('1'));
  print(value);
}
