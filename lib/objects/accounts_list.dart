import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/account.dart';

typedef AccountProvider
    = AutoDisposeStateNotifierProvider<AccountNotifier, Account>;

class AccountsList extends ChangeNotifier {
  final Map<String, AccountProvider> accounts = {};

  static AutoDisposeChangeNotifierProvider<AccountsList>? _provider;

  AccountsList._() {
    //TODO: Remove this line after the whole passwords system is complete.
    for (int i = 0; i < 10; i++) add(Account.dummy, notify: false);
  }

  static AutoDisposeChangeNotifierProvider<AccountsList> get provider {
    if (_provider == null)
      _provider = ChangeNotifierProvider.autoDispose((ref) => AccountsList._());

    return _provider!;
  }

  void add(Account account, {bool notify = true}) {
    assert(
        !accounts.containsKey(account.uuid), 'Same id password already exists');
    accounts[account.uuid] =
        StateNotifierProvider.autoDispose<AccountNotifier, Account>(
      (ref) => AccountNotifier(account),
    );
    if (notify) notifyListeners();
  }
}
