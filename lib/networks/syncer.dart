import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Syncer {
  static final collection = FirebaseFirestore.instance.collection('data');
  static const utilsSubCol = 'utils';

  ProviderRef _reader;

  static Syncer? _instance;

  Syncer._(this._reader) {
    sync();
  }

  static AutoDisposeProvider<Syncer> get instance =>
      Provider.autoDispose((ref) => Syncer._(ref));

  //TODO: Implement Sync features
  void sync() {}
}
