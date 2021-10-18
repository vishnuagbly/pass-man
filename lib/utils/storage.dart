import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webcrypto/webcrypto.dart';

class Storage {
  //Hive Globals
  static const auth = 'authStateBox';
  static const passwordsBox = 'passwordsBox';
  static const _lastLoginKey = 'lastLogin';
  static const _mPinKey = 'mPin';
  static const _mPinSaltKey = 'mPinSalt';
  static const _loginExpiryDuration = Duration(seconds: 30);

  static DateTime get _expiredDate =>
      DateTime.now().subtract(Duration(days: 1));

  static bool isTokenValid() =>
      DateTime.now().difference((Hive.box(auth)
          .get(_lastLoginKey, defaultValue: _expiredDate) as DateTime)) <
      _loginExpiryDuration;

  static void reIssueToken() {
    Hive.box(auth).put(_lastLoginKey, DateTime.now());
  }

  static Future<bool> verifyMPin(String mPin) async {
    final _box = Hive.box(auth);
    final _encryptedMPin = List<int>.from(_box.get(_mPinKey));
    final String salt = _box.get(_mPinSaltKey);

    final _rawKey = sha256.convert(utf8.encode(mPin + salt));
    final _key = await AesGcmSecretKey.importRawKey(_rawKey.bytes);
    final _mPin =
        utf8.decode(await _key.decryptBytes(_encryptedMPin, utf8.encode(salt)));
    return _mPin == mPin;
  }

  static bool mPinExists() => Hive.box(auth).get(_mPinKey) != null;

  ///Save mPin(List<int>) and salt(String).
  ///mPin is in encrypted with AES-GCM form with key as SHA-256(mPin + Salt) and
  ///IV as salt.
  ///
  /// Note: salt is 96 bits long.
  static Future<void> setMPin(String mPin) async {
    //to generate a salt of 96 bits.
    final String salt = _randomString(6);
    final _rawKey = sha256.convert(utf8.encode(mPin + salt));
    final _key = await AesGcmSecretKey.importRawKey(_rawKey.bytes);
    final _mPin = await _key.encryptBytes(utf8.encode(mPin), utf8.encode(salt));

    final _box = Hive.box(auth);
    _box.put(_mPinKey, _mPin.toList());
    _box.put(_mPinSaltKey, salt);
  }

  static void clearMPin() {
    final _box = Hive.box(auth);
    _box.delete(_mPinKey);
    _box.delete(_mPinSaltKey);
  }

  ///[length] should be in terms of 16 bits.
  static String _randomString(int length) {
    var random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }
}
