import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/storage/super_secret_key.dart';

//Need to construct this class only after successful local login, therefore
//creating this as a singleton.
///This object will consist of all the secret keys in the encrypted form
///for encryption used to encrypt data, ex- passwords and notes, in this app.
///
/// Encryption of these keys will be done using AES-GCM-256 with a super secret
/// key securely stored according to the platform.
class Secrets {
  static const String boxName = 'secretsBox';

  ///Hive key for the record that contains the [_defaultSecretId] value in the
  ///box.
  static const String __defaultSecretIdKey = 'defaultSecretKey';
  static Secrets? _instance;

  ///This is the super secret key being used to encrypt all secrets.
  late final Future<List<int>> superSecret;
  final Box _box;

  ///This is the Hive Key of the default Secret for the app, either been set
  ///by the user or automatically(i.e the first one in this case).
  String? _defaultSecretId;

  ///Will always return a default secret, if not exist then will generate one,
  ///in case there are no secrets in the local storage.
  ///
  /// To check if any secret exists in local storage check [totalSecrets].
  Future<Secret> get defaultSecret async {
    if (_defaultSecretId != null) {
      final secret = _box.get(_defaultSecretId);
      if (secret != null) return (await getSecret(__defaultSecretIdKey))!;

      //Deleting the key and setting default to null in case its value is null.
      _box.delete(_defaultSecretId);
      _defaultSecretId = null;
    }
    _defaultSecretId = await _addAndGenerateSecret();
    return (await getSecret(__defaultSecretIdKey))!;
  }

  Future<Secret?> getSecret(String id) async {
    final encodedValueMap = _box.get(id);
    if (encodedValueMap == null) return null;

    final encData = EncryptedObject.fromMap(encodedValueMap);
    final value = String.fromCharCodes(await encData.decryptData(
      Secret(bytes: await superSecret),
      force: true,
    ));

    Map<String, dynamic> secretMap = jsonDecode(value);
    return Secret.fromMap(secretMap);
  }

  Secrets._()
      : superSecret = getSuperSecret().superSecret,
        _box = Hive.box(boxName) {
    _getDefaultSecretIdIfExists().then((_) => _defaultSecretId = _);
  }

  static Future<String?> _getDefaultSecretIdIfExists() async {
    final box = Hive.box(boxName);
    //Here instead of typecasting with [String] we are typecasting with
    //[String?] as [box.get()] can also return null in case the key does not
    //exist.
    final defaultKey = box.get(__defaultSecretIdKey) as String?;
    if (defaultKey != null) return defaultKey;

    final key = box.keys.firstWhere(
      (key) => key != __defaultSecretIdKey,
      orElse: () => null,
    ) as String?;

    box.put(__defaultSecretIdKey, key);
    return key;
  }

  ///This function will take O(n) time to find totalSecrets.
  static int get totalSecrets {
    final box = Hive.box(boxName);
    int total = 0;
    box.toMap().forEach((key, value) {
      if (key != __defaultSecretIdKey && value != null) total++;
    });
    return total;
  }

  ///Generates a new secret and save the key in local storage.
  ///
  /// Returns the random-based key/id of the generated secret.
  ///
  /// Secret is generated for AES-GCM 256 bits Encryption Algorithm.
  Future<String> _addAndGenerateSecret() async {
    final algorithm = AesGcm.with256bits();
    final _secret = await (await algorithm.newSecretKey()).extractBytes();
    final secret = Secret(bytes: _secret);
    final encSecretObj = await EncryptedObject.create(
        secret.map.toString().codeUnits, Secret(bytes: await superSecret));

    Hive.box(boxName).put(
      secret.id,
      encSecretObj.map,
    );
    return secret.id;
  }

  static Secrets get instance {
    if (_instance == null) _instance = Secrets._();

    return _instance!;
  }
}
