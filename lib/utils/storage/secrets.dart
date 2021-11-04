import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/utils/storage/super_secret_key.dart';
import 'package:uuid/uuid.dart';

//Need to construct this class only after successful local login, therefore
//creating this as a singleton.
///We have a common object for both passwords and notes, as the box will contain
///data in form of json encoded strings, which will then be decoded to use.
///
/// This gives us the ability to store different types of secrets (even more
/// than 2) using a single box.
///
/// Each record/entry json encoded data should contain a parameter "type" which
/// will be a string parameter, and tell us the type of the whole (decoded
/// object)/record/entry.
class Secrets {
  static const _uuid = Uuid();
  static const String boxName = 'secretsBox';
  static const String defaultSecretKey = 'defaultKey';
  static Secrets? _instance;

  late final Future<List<int>> secretKey;
  String? _defaultKey;

  Future<String> getDefaultKey() async {
    if (_defaultKey == null) defaultKey = await __defaultKey;
    return _defaultKey!;
  }

  set defaultKey(String key) {
    if (_defaultKey != null)
      throw PlatformException(code: 'DEFAULT_KEY_NOT_NULL');

    _defaultKey = key;
  }

  Secrets._() : secretKey = getSuperSecret().superSecret {
    __defaultKey.then((_) => defaultKey = _);
  }

  static Future<String> get __defaultKey async {
    final box = Hive.box(boxName);
    //Here instead of typecasting with [String] we are typecasting with
    //[String?] as [box.get()] can also return null in case the key does not
    //exist.
    final defaultKey = box.get(defaultSecretKey) as String?;
    if (defaultKey != null) return defaultKey;

    final key = await _addKey();
    box.put(defaultSecretKey, key);
    return key;
  }

  ///Generates a new secret and save the key in local storage.
  ///
  /// Returns the random-based key/id of the generated secret.
  ///
  /// Secret is generated for AES-GCM 256 bits Encryption Algorithm.
  static Future<String> _addKey() async {
    final _key = _uuid.v4();
    final algorithm = AesGcm.with256bits();
    final secret = await (await algorithm.newSecretKey()).extractBytes();
    Hive.box(boxName).put(_key, secret);
    return _key;
  }

  static Secrets get instance {
    if (_instance == null) _instance = Secrets._();

    return _instance!;
  }
}
