import 'package:cryptography/cryptography.dart';

void main() async {
  final algo = Ecdh.p521(length: 100);
  final firstKeyPair = await algo.newKeyPair();
  final secondKeyPair = await algo.newKeyPair();

  final sharedKey = await algo.sharedSecretKey(
    keyPair: firstKeyPair,
    remotePublicKey: await secondKeyPair.extractPublicKey(),
  );

  print('key: ${(await sharedKey.extractBytes()).length}');
}
