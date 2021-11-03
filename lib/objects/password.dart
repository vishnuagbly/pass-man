import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class Password {
  static final __uuid = Uuid();

  Password({
    String? uuid,
    required this.url,
    required this.username,
    required this.password,
    this.description,
  }) : this.uuid = uuid ?? __uuid.v4();

  factory Password.fromMap(Map<String, dynamic> _map) {
    assert(
        _map['uuid'] != null &&
            _map['url'] != null &&
            _map['username'] != null &&
            _map['password'] != null,
        'SOME REQUIRED FIELD IS NULL');

    return Password(
      uuid: _map['uuid'],
      url: _map['url'],
      username: _map['username'],
      password: _map['password'],
      description: _map['description'],
    );
  }

  static Password get dummy => Password(
        username: 'dummy username',
        url: 'dummy url',
        password: 'dummy password',
      );

  final String uuid;
  final String url;
  final String username;
  final String password;
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is Password &&
      other.runtimeType == runtimeType &&
      other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  Map<String, String?> toMap() => {
        'uuid': uuid,
        'url': url,
        'username': username,
        'password': password,
        'description': description,
      };

  @override
  String toString() => jsonEncode(toMap());
}

class PasswordNotifier extends StateNotifier<Password> {
  PasswordNotifier(Password password) : super(password);

  PasswordNotifier.fromMap(Map<String, String> map)
      : super(Password.fromMap(map));

  void update(Password password) {
    assert(password.uuid == state.uuid, 'Not same passwords');

    state = password;
  }
}
