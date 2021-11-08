import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/networks/syncer.dart';

class Changes {
  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return Syncer.collection.doc('$uid/${Syncer.utilsSubCol}/changes');
  }

  ///Check if the Changes doc exists and if not creates one.
  static Future<void> initialize() async {
    final snapshot = await _doc.get();
    if (snapshot.data() == null) await _doc.set({});
  }

  Stream<Map<String, DateTime>> get stream => _doc.snapshots().map((snapshot) {
        return (snapshot.data() ?? {})
            .map((key, value) => MapEntry(key, value.toDate()));
      });

  ///Can be used for add, edit and delete operations. For delete set value for
  ///the respective key to null in [map].
  void update(Map<String, DateTime?> map, Transaction transaction) {
    Map<String, dynamic> res = {};
    for (final key in map.keys) {
      if (map[key] == null)
        res[key] = FieldValue.delete();
      else
        res[key] = map[key];
    }
    transaction.update(_doc, res);
  }
}
