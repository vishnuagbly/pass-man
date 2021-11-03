import 'package:passman/utils/storage/super_secret_key.dart';

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
  static const String boxName = 'secretsBox';
  static Secrets? _instance;

  late final Future<List<int>> secretKey;

  Secrets._() : secretKey = getSuperSecret().superSecret;

  static Secrets get instance {
    if (_instance == null) _instance = Secrets._();

    return _instance!;
  }
}
