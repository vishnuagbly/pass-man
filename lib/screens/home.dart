import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:helpful_components/common_snapshot_responses.dart';
import 'package:helpful_components/helpful_components.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/screens/mpass.dart';
import 'package:passman/utils/globals.dart';

import 'add_update_note.dart';
import 'add_update_account.dart';

class HomeScreen extends StatefulWidget {
  static const route = "/home";

  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _provider = AccountsList.provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: FutureBuilder<AccountsListProvider>(
          future: _provider,
          builder: (context, snapshot) {
            return CommonAsyncSnapshotResponses(
              snapshot,
              builder: (AccountsListProvider _provider) => Consumer(
                builder: (_, ref, __) {
                  final _accountsList = ref.watch(_provider);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListView.builder(
                      itemCount: _accountsList.accounts.values.length,
                      itemBuilder: (_, i) =>
                          Consumer(builder: (context, _ref, _) {
                        final _accProvider =
                            _accountsList.accounts.values.toList()[i];
                        final _url = _ref
                            .watch(_accProvider.select((value) => value.url));
                        final key = GlobalKey();
                        return Card(
                          key: key,
                          child: InkWell(
                            //TODO: Add Remove Functionality
                            onTap: () {
                              Modular.to.pushNamed(
                                AddUpdateAccount.route,
                                arguments: _accProvider,
                              );
                            },
                            onLongPress: () {
                              showPopup(
                                  showBarrierColor: true,
                                  context: context,
                                  builder: (overlayEntry) => Popup(
                                        parentKey: key,
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: TextButton(
                                              onPressed: () {
                                                _ref.read(_provider).remove(
                                                    _ref.read(_accProvider));
                                                overlayEntry.remove();
                                              },
                                              child: Text(
                                                'Delete',
                                                style: Globals.kBodyText1Style
                                                    .copyWith(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ));
                            },

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
                  );
                },
              ),
            );
          }),
      floatingActionButton: SpeedDial(
        child: Icon(Icons.add),
        children: [
          SpeedDialChild(
            label: "Add/update Password",
            child: Icon(Icons.security),
            onTap: () {
              Modular.to.pushNamed(AddUpdateAccount.route);
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
    );
  }
}
