import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/utils/utils.dart';

typedef AccountProvider
    = AutoDisposeStateNotifierProvider<AccountNotifier, Account>;
typedef AccountsListProvider = AutoDisposeChangeNotifierProvider<AccountsList>;

class AccountsList extends ChangeNotifier {
  final Map<String, AccountProvider> accounts = {};
  int encryptedAccounts;

  static AutoDisposeChangeNotifierProvider<AccountsList>? _provider;

  AccountsList._(List<Account> accounts, [this.encryptedAccounts = 0]) {
    accounts.forEach((account) => add(
          account,
          notify: false,
          onlyInMemory: true,
        ));
    print('unDecrypted Accounts: $encryptedAccounts');
  }

  static Future<AccountsListProvider> get provider async {
    if (_provider == null) {
      int encAccounts = 0;
      final List<Account> accounts = [];
      final _data = Database.instance.data;
      _data.removeWhere((key, elem) => elem.type != Account.typeName);

      // print('total secrets: ${Secrets.instance.allSecretsIds()}');
      _data.forEach((key, elem) async {
        // print('secret id: ${elem.secretId}');
        final secret = await Secrets.instance.getSecret(elem.secretId);
        if (secret == null) {
          //The below line is temporary for until we have added the
          //functionality to show the unencrypted passwords, the
          //functionality to delete them, the whole firestore system.
          //TODO: Remove below line after above comment is implemented.
          Database.instance.delete(key).catchError((err) {
            print("error: $err");
            encAccounts++;
          });
          return;
        }

        accounts.add(Account.fromMap(await elem.decryptToMap(secret)));
      });

      _provider = ChangeNotifierProvider.autoDispose(
          (ref) => AccountsList._(accounts, encAccounts));
    }

    return _provider!;
  }

  void add(
    Account account, {
    bool notify = true,
    bool onlyInMemory = false,
  }) {
    assert(
        !accounts.containsKey(account.uuid), 'Same id password already exists');

    if (!onlyInMemory)
      account.uploadToDatabase().catchError((err) {
        print(err);
        remove(account);
      });
    //TODO: Add logic to add account in Firestore.
    accounts[account.uuid] =
        StateNotifierProvider.autoDispose<AccountNotifier, Account>(
      (ref) => AccountNotifier(account),
    );
    print("Account Added!");
    if (notify) notifyListeners();
  }

  void remove(Account account) {
    //TODO: Add logic to remove account from firestore.
    //TODO: Remove [completeDelete] after the above is implemented.
    Database.instance
        .delete(account.uuid, completeDelete: true)
        .catchError((err) {
      print(err);
      add(account);
    });
    accounts.remove(account.uuid);
    print("Account Removed!");
    notifyListeners();
  }
}
