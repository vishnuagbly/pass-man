import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/networks/syncer.dart';
import 'package:uuid/uuid.dart';

///These functions are only to be used before checking that you are logged in
///and are connected to the internet.
///
///Make sure that the format exists before using any other functions.
abstract class Format {
  static final _loggedOutException =
      PlatformException(code: 'NO_FORMAT_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return Syncer.collection.doc('$uid/${Syncer.utilsSubCol}/format');
  }

  ///Check if the format doc exists and if not creates one.
  static Future<void> initialize() async {
    final snapshot = await _doc.get();
    if (snapshot.data() == null) await _doc.set({});
  }

  static Stream<Map<String, List<String>>> get stream {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      return _converter(data ?? {});
    });
  }

  static Future<Map<String, List<String>>> value(
      [Transaction? transaction]) async {
    final _convert = (snapshot) => _converter(snapshot.data() ?? {});

    if (transaction != null) {
      return transaction.get(_doc).then(_convert);
    }
    return _doc.get().then(_convert);
  }

  static Map<String, List<String>> _converter(Map<String, dynamic> _map) {
    Map<String, List<String>> res = {};
    _map.forEach((key, val) => res[key] = List<String>.from(val));
    return res;
  }

  ///This function can be used to perform add, edit and delete all of them.
  ///
  ///Here since we need to provide the [format] gotten using transaction, as in
  ///case of transaction we need to perform all read operations first, therefore
  ///they cannot be performed inside a same function.
  ///
  /// This function returns the [docId] used. This is helpful to get the
  /// auto selected value of [docId] used by the function in case if it was not
  /// specified in the parameters.
  static String? update(
    String fileId,
    Transaction transaction,
    Map<String, List<String>> format, {
    bool delete = false,
    String? docId,
  }) {
    Map<String, List<String>> toUpdate = {};
    for (final key in format.keys) {
      int total = format[key]!.fold(0, (previousValue, element) {
        if (element == fileId) previousValue++;
        return previousValue;
      });
      if (key == docId || total > 0)
        format[key] = [
          ...format[key]!.where((elem) => elem != fileId).toList(),
          if (key == docId && !delete) fileId,
        ];
      toUpdate[key] = format[key]!;
    }
    if (docId == null && !delete) {
      String? _min;
      for (final key in format.keys) {
        if (_min == null || format[key]!.length < format[_min]!.length)
          _min = key;
      }
      if (_min == null) _min = Uuid().v1();
      toUpdate[_min] = [...format[_min]!, fileId];
      docId = _min;
    }
    transaction.update(_doc, toUpdate);
    return docId;
  }
}
