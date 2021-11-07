import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/objects/encrypted_object.dart';
import 'package:passman/utils/utils.dart';

typedef AccountProvider
    = AutoDisposeStateNotifierProvider<AccountNotifier, Account>;
typedef AccountsListProvider = AutoDisposeChangeNotifierProvider<AccountsList>;

class AccountsList extends ChangeNotifier {
  final Map<String, AccountProvider> accounts;
  int encryptedAccounts;

  static AccountsListProvider? _provider;
  static AccountsList? _instance;

  AccountsList._(List<Account> accounts, [this.encryptedAccounts = 0])
      : accounts = {} {
    accounts.forEach((account) => add(
          account,
          notify: false,
          onlyInMemory: true,
        ));
    print('unDecrypted Accounts: $encryptedAccounts');
  }

  AccountsList._copyWith(AccountsList accountsList)
      : encryptedAccounts = accountsList.encryptedAccounts,
        accounts = accountsList.accounts;

  static Future<AccountsListProvider> get provider async {
    if (_provider == null) {
      if (_instance == null) {
        int encAccounts = 0;
        final List<Account> accounts = [];
        final _data = Database.instance.data
            .where((elem) => elem.type == Account.typeName);

        for (final elem in _data) {
          final secret = await Secrets.instance.getSecret(elem.secretId);
          if (secret == null) {
            encAccounts++;
            continue;
          }

          accounts.add(Account.fromString(
              String.fromCharCodes(await elem.decryptData(secret))));
        }

        _instance = AccountsList._(accounts, encAccounts);
      }

      _provider = ChangeNotifierProvider.autoDispose(
        //Here this function will be called each time we will access the
        //[_provider] so, we cannot create the object inside this parameter with
        //local variables with values asynchronously generated, as values for
        //those will not be recomputed and we cannot put await calls inside this
        //function so, instead we will be calling the [_copyWith] constructor
        //on a private singleton instance, here a constructor is necessary as
        //due to auto dispose, after disposing the object we could not re-listen
        //the same instance.
        (ref) {
          //here we are re-assigning [_instance] so that, by accessing the
          //[_provider] we will be accessing and updating the [_instance] only
          //as on next invocation of this parameter new object which will be
          //created, will be of the lastly updated [_instance].
          _instance = AccountsList._copyWith(_instance!);
          return _instance!;
        },
      );
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
