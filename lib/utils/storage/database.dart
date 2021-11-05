import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:uuid/uuid.dart';

//Creating this as a singleton for the same reason as for the [Secrets] class
//in "secrets.dart" file.
///We have a common object for both passwords and notes, as the box will contain
///data in form of [EncryptedObject] maps, which will then be decoded to use.
///
/// This gives us the ability to store different types of secrets (even more
/// than 2) using a single box.
///
/// Each record/entry json encoded data should contain a parameter "type" which
/// will be a string parameter, and tell us the type of the whole (decoded
/// object)/record/entry.
class Database {
  static const String boxName = 'AccountStorageBox';
  static Database? _instance;

  List<EncryptedObject> get data => Hive.box(boxName)
      .values
      .map((elem) => EncryptedObject.fromMap(Map<String, dynamic>.from(elem)))
      .toList();

  Database._();

  static Database get instance {
    if (_instance == null) _instance = Database._();
    return _instance!;
  }

  Future<void> add(EncryptedObject encryptedObject, [String? _key]) async {
    var key = _key ?? Uuid().v4();

    while (Hive.box(boxName).containsKey(key)) {
      if (_key != null) throw PlatformException(code: 'KEY_ALREADY_EXISTS');
      key = Uuid().v4();
    }

    Hive.box(boxName).put(key, encryptedObject.map);
  }

  ///This deletes the record/data from the [Database] box and add the
  ///(Hive key)/(Data id) to the [Deleted] box.
  Future<void> delete(String? key) async {
    //TODO: Add logic for this.
  }
}
