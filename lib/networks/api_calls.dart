import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

abstract class Api {
  static Future<bool> isStrong(String password) async {
    final url = 'https://psiss.herokuapp.com/psiss/score';
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'password': password}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) return body['score'] > 2;

    throw PlatformException(code: 'ERROR');
  }

  static Future<String> logo(String url) async {
    final httpCallUrl =
        'https://logo-extractor-232.herokuapp.com/allicons.json?url=$url';

    final res = await http.get(Uri.parse(httpCallUrl));

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) return body['icons'][0]['url'];

    throw PlatformException(code: 'ERROR');
  }
}
