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
    accounts.forEach((account) => add(
          account,
          notify: false,
          onlyInMemory: true,
        ));
    print('unDecrypted Accounts: $encryptedAccounts');
  }

  static Future<AccountsListProvider> get provider async {
    print("getting accounts provider");
    if (_provider == null) {
      print("accounts provider is null");
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

        accounts.add(Account.fromString(
            String.fromCharCodes(await elem.decryptData(secret))));
      }

      //Here this function is being re-called on Hot Reload in debug mode still
      //hasn't tested whether it is a problem but could be, as in debug mode on
      //re-builds after adding accounts it is causing the newly added accounts
      //disappear as the values of [accounts] and [encAccounts] used in this
      //function will remain same.
      //TODO: Fix the issue mentioned in above comments.
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
      _addToDatabase(account).catchError((err) {
        print(err);
        remove(account.uuid);
      });
    //TODO: Add logic to add account in Firestore.
    accounts[account.uuid] =
        StateNotifierProvider.autoDispose<AccountNotifier, Account>(
      (ref) => AccountNotifier(account),
    );
    print("Account Added!");
    if (notify) notifyListeners();
  }

  Future<void> _addToDatabase(Account account) async {
    final secret = await Secrets.instance.defaultSecret;
    print("added to database with secretId: ${secret.id}");
    final encObj = await EncryptedObject.create(
        account.toString().codeUnits, secret,
        type: Account.typeName);
    return Database.instance.add(encObj, account.uuid);
  }

  void remove(String uuid) {
    //TODO: Add logic to remove account from local storage and firestore.
    accounts.remove(uuid);
    print("Account Removed!");
    notifyListeners();
  }
}
