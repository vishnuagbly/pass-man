import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/password.dart';

class PasswordsList extends ChangeNotifier {
  final Map<String,
          AutoDisposeStateNotifierProvider<PasswordNotifier, Password>>
      _passwords = {};

  static AutoDisposeChangeNotifierProvider<PasswordsList>? _provider;

  PasswordsList._();

  static AutoDisposeChangeNotifierProvider<PasswordsList> get provider {
    if (_provider == null)
      _provider =
          ChangeNotifierProvider.autoDispose((ref) => PasswordsList._());

    return _provider!;
  }

  void add(Password password) {
    assert(!_passwords.containsKey(password.uuid),
        'Same id password already exists');
    _passwords[password.uuid] =
        StateNotifierProvider.autoDispose<PasswordNotifier, Password>(
      (ref) => PasswordNotifier(password),
    );
  }
}
