import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecretSyncer {
  final AutoDisposeProviderRef _ref;
  Map<String, SecretKey> sharedSecrets;

  static SecretSyncer? _instance;
  static AutoDisposeProvider<SecretSyncer>? _provider;

  SecretSyncer._(this._ref, {Map<String, SecretKey>? sharedSecrets})
      : sharedSecrets = sharedSecrets ?? {} {
    _initialize().then((_) => _sync());
  }

  static AutoDisposeProvider<SecretSyncer> get instance {
    if (_provider == null) {
      _provider = Provider.autoDispose((ref) {
        if (_instance == null) _instance = SecretSyncer._(ref);

        return _instance!;
      });
    }

    return _provider!;
  }

  Future<void> _initialize() async {
    //TODO: Implement this function
  }

  void _sync() {
    //TODO: Implement this function
  }
}
