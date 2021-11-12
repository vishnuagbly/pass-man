import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passman/networks/account_syncer.dart';
import 'package:passman/utils/storage/auth.dart';

class SecretsNetwork {
  static final _loggedOutException =
      PlatformException(code: 'NO_SECRETS_LOGGED_OUT');

  static DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw _loggedOutException;

    return AccountSyncer.collection.doc('$uid/secrets/${AuthStorage.deviceId}');
  }
}
