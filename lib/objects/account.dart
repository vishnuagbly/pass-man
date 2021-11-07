import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/extensions/encryption.dart';
import 'package:passman/utils/utils.dart';
import 'package:uuid/uuid.dart';

class Account {
  static final __uuid = Uuid();
  static const typeName = 'account';

  Account({
    String? uuid,
    required this.url,
    required this.username,
    required this.password,
    this.description = '',
  })  : assert(url.isNotEmpty && username.isNotEmpty && password.isNotEmpty),
        this.uuid = uuid ?? __uuid.v4();

  factory Account.fromMap(Map<String, dynamic> _map) {
    assert(
        _map['uuid'] != null &&
            _map['url'] != null &&
            _map['username'] != null &&
            _map['password'] != null,
        'SOME REQUIRED FIELD IS NULL');

    return Account(
      uuid: _map['uuid'],
      url: _map['url'],
      username: _map['username'],
      password: _map['password'],
      description: _map['description'] ?? '',
    );
  }

  static Account get dummy => Account(
        username: 'dummy username',
        url: 'dummy url',
        password: 'dummy password',
      );

  final String uuid;
  final String url;
  final String username;
  final String password;
  final String description;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.runtimeType == runtimeType &&
      other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  Map<String, String> get map => {
        'uuid': uuid,
        'url': url,
        'username': username,
        'password': password,
        'description': description,
      };

  @override
  String toString() => jsonEncode(map);

  Future<void> uploadToDatabase() async =>
      Database.instance.upload(await map.toEncObj(Account.typeName), uuid);
}

class AccountNotifier extends StateNotifier<Account> {
  AccountNotifier(Account account) : super(account);

  AccountNotifier.fromMap(Map<String, String> map)
      : super(Account.fromMap(map));

  void update(Account account) {
    assert(account.uuid == state.uuid, 'Not same passwords');

    final temp = state.map;

    account
        .uploadToDatabase()
        .catchError((err) => state = Account.fromMap(temp));
    //TODO: Add Firestore Logic

    state = account;
  }
}
