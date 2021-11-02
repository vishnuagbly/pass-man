import 'package:passman/utils/storage/super_secret_key.dart';

//Need to construct this class only after successful local login, therefore
//creating this as a singleton.
class Secrets {
  static const String boxName = 'secretsBox';
  static Secrets? _instance;

  late final Future<List<int>> secretKey;

  Secrets._() : secretKey = getSuperSecret().superSecret;

  static Secrets get instance {
    if (_instance == null) _instance = Secrets._();

    return _instance!;
  }
}
