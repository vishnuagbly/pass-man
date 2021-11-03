import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:passman/objects/password_list.dart';
import 'package:passman/screens/mpass.dart';
import 'package:passman/utils/globals.dart';

import 'add_update_note.dart';
import 'add_update_password.dart';

import 'lock_screen.dart'
    if (dart.library.io) 'lock_screen_mobile.dart'
    if (dart.library.html) 'lock_screen_web.dart';

class HomeScreen extends ConsumerWidget {
  static const route = "/home";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final _passwordsList = ref.watch(PasswordsList.provider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text("Home"),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: FirebaseAuth.instance.signOut,
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                IconButton(
                  onPressed: () => Modular.to.pushNamed(MPassword.route),
                  icon: Icon(Icons.vpn_key),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              itemCount: _passwordsList.passwords.values.length,
              itemBuilder: (_, i) => Consumer(builder: (context, _ref, _) {
                final _passProvider =
                    _passwordsList.passwords.values.toList()[i];
                final _url =
                    _ref.watch(_passProvider.select((value) => value.url));
                return Card(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      child: Center(
                        child: Text(
                          _url,
                          style: TextStyle(fontSize: 4.w),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          floatingActionButton: SpeedDial(
            child: Icon(Icons.add),
            children: [
              SpeedDialChild(
                label: "Add/update Password",
                child: Icon(Icons.security),
                onTap: () {
                  Modular.to.pushNamed(AddUpdatePassword.route);
                },
              ),
              SpeedDialChild(
                label: "Add/update Note",
                child: Icon(Icons.note_add),
                onTap: () {
                  Modular.to.pushNamed(AddUpdateNote.route);
                },
              ),
            ],
          ),
        ),
        lockScreen(),
      ],
    );
  }
}
