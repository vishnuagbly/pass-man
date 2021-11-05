import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/utils.dart';

typedef AccountProvider
    = AutoDisposeStateNotifierProvider<AccountNotifier, Account>;
typedef AccountsListProvider = AutoDisposeChangeNotifierProvider<AccountsList>;

class AccountsList extends ChangeNotifier {
  final Map<String, AccountProvider> accounts = {};
  int encryptedAccounts;

  static AutoDisposeChangeNotifierProvider<AccountsList>? _provider;

  AccountsList._(List<Account> accounts, [this.encryptedAccounts = 0]) {
    accounts.forEach((account) => add(account, notify: false));
  }

  static Future<AccountsListProvider> get provider async {
    if (_provider == null) {
      int encAccounts = 0;
      final List<Account> accounts = [];
      final _data =
          Database.instance.data.where((elem) => elem.type == Account.typeName);
      for (final elem in _data) {
        final secret = await Secrets.instance.getSecret(elem.secretId);
        if (secret == null) {
          encAccounts++;
          continue;
        }
        Map<String, dynamic> map =
            jsonDecode(String.fromCharCodes(await elem.decryptData(secret)));

        accounts.add(Account.fromMap(map));
      }
      _provider = ChangeNotifierProvider.autoDispose(
          (ref) => AccountsList._(accounts, encAccounts));
    }

    return _provider!;
  }

  void add(Account account, {bool notify = true}) {
    assert(
        !accounts.containsKey(account.uuid), 'Same id password already exists');

    _addToDatabase(account).catchError((err) {
      print(err);
      remove(account.uuid);
    });
    //TODO: Add logic to add account in Firestore.
    accounts[account.uuid] =
        StateNotifierProvider.autoDispose<AccountNotifier, Account>(
      (ref) => AccountNotifier(account),
    );
    if (notify) notifyListeners();
  }

  Future<void> _addToDatabase(Account account) async {
    final secret = await Secrets.instance.defaultSecret;
    final encObj =
        await EncryptedObject.create(account.toString().codeUnits, secret);
    return Database.instance.add(encObj, account.uuid);
  }

  void remove(String uuid) {
    //TODO: Add logic to remove account from local storage and firestore.
    accounts.remove(uuid);
    notifyListeners();
  }
}
