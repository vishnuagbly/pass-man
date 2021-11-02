import 'package:cryptography/cryptography.dart';

import 'super_secret_key_web.dart'
    if (dart.library.io) 'super_secret_key_mobile.dart';

SuperSecret getSuperSecret() => superSecret;

abstract class SuperSecret {
  Future<List<int>> get superSecret;

  Future<List<int>> generateKey() async {
    final algorithm = AesGcm.with256bits();
    return (await algorithm.newSecretKey()).extractBytes();
  }
}
