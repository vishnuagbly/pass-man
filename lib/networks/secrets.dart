import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/networks/account_syncer.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/storage/auth.dart';

abstract class SecretsNetwork {
  static final _loggedOutException =
      PlatformException(code: 'NO_SECRETS_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc =>
      getDocRef(AuthStorage.deviceId);

  static DocumentReference<Map<String, dynamic>> getDocRef(String deviceId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection.doc('$uid/secrets/$deviceId}');
  }

  static void clear(Transaction transaction) =>
      transaction.set(_doc, <String, dynamic>{});

  static Stream<Map<String, Map<String, dynamic>>> get stream =>
      _doc.snapshots().map((snapshot) => (snapshot.data() ?? {}).map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value))));

  static Future<Map<String, Secret>> convert(
      Map<String, Map<String, dynamic>> data,
      Map<String, List<int>> sharedSecrets) async {
    Map<String, Secret> res = {};
    for (final key in data.keys) {
      final secret = sharedSecrets[key];
      if (secret == null) continue;
      res[key] = await _convert(data[key]!, secret);
    }
    return res;
  }

  static Future<Secret> _convert(
      Map<String, dynamic> _encryptedMap, List<int> sharedSecret) async {
    final encObj = EncryptedObject.fromMap(_encryptedMap);
    final secret = await Sha256().hash(sharedSecret);
    final _map =
        await encObj.decryptToMap(Secret(bytes: secret.bytes), force: true);
    return Secret.fromMap(_map);
  }
}
