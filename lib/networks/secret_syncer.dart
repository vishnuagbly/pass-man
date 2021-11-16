import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/networks/secrets.dart';
import 'package:passman/networks/share_secret.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/utils/utils.dart';

class SecretSyncer {
  final AutoDisposeProviderRef _ref;
  Map<String, SecretKey> sharedSecrets;
  StreamSubscription? _subscription;

  static SecretSyncer? _instance;
  static AutoDisposeProvider<SecretSyncer>? _provider;

  SecretSyncer._(this._ref, {Map<String, SecretKey>? sharedSecrets})
      : sharedSecrets = sharedSecrets ?? {} {
    _sync();
  }

  static Future<AutoDisposeProvider<SecretSyncer>> get instance async {
    if (_provider == null) {
      _provider = Provider.autoDispose((ref) {
        if (_instance == null) _instance = SecretSyncer._(ref);

        return _instance!;
      });
    }

    return _provider!;
  }

  ///Should only be called on logout
  Future<void> dispose() async {
    await Future.wait([
      _subscription?.cancel() ?? Future.value(null),
      _ref.read(SSNetwork.instance).cancel(),
    ]);

    _instance = null;
  }

  void _sync() {
    print('secret syncer started');
    _subscription = SecretsNetwork.stream.listen((secretsMap) {
      print('received_secrets updated');
      print('total received_secrets: ${secretsMap.length}');
      _ref.listen(SSNetwork.instance, (SSNetwork ssNetwork) async {
        print('shared keys updated');
        print('total shared keys: ${ssNetwork.sharedKeys.length}');
        await _toLocal(ssNetwork, secretsMap);
        _toOnline(ssNetwork);
        _ref.read(await AccountsList.provider).reloadEncObjs();
      }, fireImmediately: true);
    });
  }

  Future<void> _toLocal(
    SSNetwork ssNetwork,
    Map<String, Map<String, dynamic>> secretsMap,
  ) async {
    final secrets =
        await SecretsNetwork.convert(secretsMap, ssNetwork.sharedKeys);

    final List<Future> futures = [];

    secrets.forEach((key, value) async {
      final secret = await Secrets.instance.getSecret(value.id);
      if (secret != null) return;
      futures.add(Secrets.instance.add(value));
    });

    await Future.wait(futures);
  }

  Future<void> _toOnline(SSNetwork ssNetwork) async {
    final toSetDocs = await ssNetwork.toSetDocs;
    await FirebaseFirestore.instance.runTransaction(
      (transaction) async => ssNetwork.upload(transaction, toSetDocs),
    );
  }
}
