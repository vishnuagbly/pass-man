import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/password.dart';

class PasswordsList extends ChangeNotifier {
  final Map<String,
          AutoDisposeStateNotifierProvider<PasswordNotifier, Password>>
      passwords = {};

  static AutoDisposeChangeNotifierProvider<PasswordsList>? _provider;

  PasswordsList._() {
    //TODO: Remove this line after the whole passwords system is complete.
    for (int i = 0; i < 10; i++) add(Password.dummy);
  }

  static AutoDisposeChangeNotifierProvider<PasswordsList> get provider {
    if (_provider == null)
      _provider =
          ChangeNotifierProvider.autoDispose((ref) => PasswordsList._());

    return _provider!;
  }

  void add(Password password, {bool notify = true}) {
    assert(!passwords.containsKey(password.uuid),
        'Same id password already exists');
    passwords[password.uuid] =
        StateNotifierProvider.autoDispose<PasswordNotifier, Password>(
      (ref) => PasswordNotifier(password),
    );
    if (notify) notifyListeners();
  }
}
