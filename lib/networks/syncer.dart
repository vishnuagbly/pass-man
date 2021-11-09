import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/networks/accounts.dart';
import 'package:passman/networks/changes.dart';
import 'package:passman/networks/deleted.dart';
import 'package:passman/networks/format.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/utils/storage/deleted.dart';

class Syncer {
  static final collection = FirebaseFirestore.instance.collection('data');
  static const utilsSubCol = 'utils';

  AutoDisposeProviderRef _ref;
  bool syncRunning = false;

  static Syncer? _instance;

  Syncer._(this._ref) {
    sync();
  }

  static Future<AutoDisposeProvider<Syncer>> get instance async {
    await Future.wait([
      Changes.initialize(),
      Format.initialize(),
      DeletedNetworks.initialize(),
    ]);
    return Provider.autoDispose((ref) => Syncer._(ref));
  }

  //TODO: Implement Sync features
  void sync() {
    Changes.stream.listen((changes) async {
      final deletedOnline = DeletedNetworks.data;
      _ref.listen(await AccountsList.provider,
          (AccountsList accountsList) async {
        _performSync(changes, accountsList, deletedOnline);
      });
    });
  }

  Future<void> _performSync(
      Map<String, DateTime> changes,
      AccountsList accountsList,
      Future<Map<String, DateTime>> deletedOnline) async {
    if (syncRunning) return;
    syncRunning = true;

    final accounts = accountsList.accounts;
    final List<String> toLocal = [], toOnline = [];
    for (final key in changes.keys) {
      final provider = accounts[key];
      if (provider == null) {
        if ((await deletedOnline).containsKey(key)) continue;
        final deletedTime = Deleted.instance.find(key);
        if (deletedTime == null || changes[key]!.isAfter(deletedTime))
          toLocal.add(key);
        else
          toOnline.add(key);
        continue;
      }

      final account = _ref.read(provider);
      if (changes[key]!.isAfter(account.updated))
        toLocal.add(key);
      else if (changes[key]! != account.updated) toOnline.add(key);
    }
    final format = Format.value();
    await Future.wait([
      _syncToLocal(toLocal, deletedOnline, format),
      _syncToOnline(toOnline, deletedOnline, format)
    ]);

    syncRunning = false;
    await Future.delayed(Duration(minutes: 1));
    if (syncRunning) return;
    _performSync(
      await Changes.value,
      _ref.read(await AccountsList.provider),
      DeletedNetworks.data,
    );
  }

  Future<void> _syncToLocal(
    List<String> keys,
    Future<Map<String, DateTime>> _deletedOnline,
    Future<Map<String, List<String>>> _format,
  ) async {
    final deletedOnline = await _deletedOnline;
    final format = Format.toAccountIdDocId(await _format);
    final accountsList = _ref.read(await AccountsList.provider);
    Map<String, Set<String>> accountsToGet = {};
    for (final key in keys) {
      if (deletedOnline.containsKey(key)) {
        final accProvider = accountsList.accounts[key];
        if (accProvider == null) continue;
        accountsList.remove(_ref.read(accProvider));
        continue;
      }
      final docId = format[key];
      if (docId == null) continue;
      accountsToGet[docId] = (accountsToGet[docId] ?? Set())..add(key);
    }

    final accounts = await AccountsNetwork.values(accountsToGet);
    accounts.forEach((key, value) {
      if (value == null) return;
      if (accountsList.accounts[key] == null) {
        accountsList.add(value);
        return;
      }
      _ref.read(accountsList.accounts[key]!.notifier).update(value);
    });
  }

  Future<void> _syncToOnline(
    List<String> keys,
    Future<Map<String, DateTime>> _deletedOnline,
    Future<Map<String, List<String>>> _format,
  ) async {
    //TODO: add Implementation
    final deletedOnline = await _deletedOnline;
    final format = Format.toAccountIdDocId(await _format);


    for (final key in keys) {
      final deletedTime = Deleted.instance.find(key);
      if (deletedTime != null) {

      }
    }
  }
}
