import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/networks/secrets.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/objects/secret.dart';
import 'package:passman/utils/utils.dart';

import 'account_syncer.dart';

///Share Secret Network object is used to share your public secret on firestore
///database.
class SSNetwork extends ChangeNotifier {
  static final _firestore = FirebaseFirestore.instance;

  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection
        .doc('$uid/${AccountSyncer.utilsSubCol}/shared_secrets');
  }

  static SSNetwork? _instance;
  static AutoDisposeChangeNotifierProvider<SSNetwork>? _provider;

  late final SimpleKeyPair keyPair;
  final Map<String, List<int>> sharedKeys = {};
  StreamSubscription? _subscription;

  SSNetwork._() {
    _sync();
  }

  static AutoDisposeChangeNotifierProvider<SSNetwork> get instance {
    if (_provider == null)
      _provider = ChangeNotifierProvider.autoDispose((ref) {
        if (_instance == null) _instance = SSNetwork._();

        return _instance!;
      });

    return _provider!;
  }

  ///Should be called on logout only
  Future<void> cancel() async {
    await _subscription?.cancel();
    _instance = null;
  }

  Future<void> _initialize() async {
    final algorithm = X25519();

    final keyPair = await algorithm.newKeyPair();
    this.keyPair = keyPair;

    final publicKey = await keyPair.extractPublicKey();

    if ((await _doc.get()).data() == null) await _doc.set({});

    await _firestore.runTransaction((transaction) async {
      _update(publicKey.bytes, transaction);
      SecretsNetwork.clear(transaction);
    });
  }

  static void _update(List<int> publicKey, Transaction transaction) =>
      transaction.update(_doc, {AuthStorage.deviceId: publicKey});

  static Future<Map<String, List<int>>> get doc =>
      _doc.get().then((snapshot) => (snapshot.data() ?? {})
          .map((key, value) => MapEntry(key, List<int>.from(value))));

  static Stream<Map<String, List<int>>> get _stream =>
      _doc.snapshots().map((snapshot) => (snapshot.data() ?? {})
          .map((key, value) => MapEntry(key, List<int>.from(value))));

  void _sync() async {
    await _initialize();
    _subscription = _stream.listen((values) {
      values.forEach((key, value) async =>
          sharedKeys[key] = await (await _getSharedKey(value)).extractBytes());
      notifyListeners();
    });
  }

  Future<SecretKey> _getSharedKey(final List<int> remotePubicKey) async =>
      X25519().sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey:
            SimplePublicKey(remotePubicKey, type: KeyPairType.x25519),
      );

  Future<Set<String>> get toSetDocs async {
    final List<Future> futures = [];
    final res = Set<String>();

    sharedKeys.forEach((deviceId, value) {
      futures.add((() async {
        final value = await SecretsNetwork.getDocRef(deviceId).get();
        if (value.data() == null) res.add(deviceId);
      })());
    });

    await Future.wait(futures);
    return res;
  }

  Future<void> upload(Transaction transaction, Set<String> toSet) async {
    final secrets = await Secrets.instance.all();

    sharedKeys.forEach((deviceId, secretKey) async {
      Map<String, Map<String, dynamic>> toUpdate = {};
      final sharedSecret =
          Secret(bytes: (await Sha256().hash(secretKey)).bytes);
      secrets.forEach((key, value) async {
        toUpdate[AuthStorage.deviceId] = (await EncryptedObject.create(
                value.toString().codeUnits, sharedSecret))
            .map;
      });

      if (toSet.contains(deviceId))
        transaction.update(SecretsNetwork.getDocRef(deviceId), toUpdate);
      else
        transaction.set(SecretsNetwork.getDocRef(deviceId), toUpdate);
    });
  }
}
