import 'package:flutter/material.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman/objects/account.dart';
import 'package:passman/objects/accounts_list.dart';
import 'package:passman/utils/globals.dart';
import 'package:passman/utils/utils.dart';

class AddUpdateAccount extends ConsumerStatefulWidget {
  static const route = '/add-update-password';

  const AddUpdateAccount({
    Key? key,
    this.account,
  }) : super(key: key);

  final AccountProvider? account;

  @override
  _AddUpdateAccountState createState() => _AddUpdateAccountState();
}

class _AddUpdateAccountState extends ConsumerState<AddUpdateAccount> {
  final formKey = GlobalKey<FormState>();
  late final String? _uuid;
  final _password = TextEditingController(),
      _username = TextEditingController(),
      _url = TextEditingController(),
      _description = TextEditingController();
  bool hidePassword = true;

  void onSubmit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final account = Account(
      uuid: _uuid,
      url: _url.text,
      password: _password.text,
      username: _username.text,
      description: _description.text,
    );
    final accountProvider = widget.account;
    if (accountProvider != null) {
      //TODO: Add account UPDATE both locally and online logic
      final accountNotifier = ref.read(accountProvider.notifier);
      accountNotifier.update(account);
      return;
    }
    //TODO: Add account ADD both locally and online logic
    final accounts = ref.read(await AccountsList.provider);
    accounts.add(account);
  }

  @override
  void initState() {
    final accountProvider = widget.account;
    if (accountProvider != null) {
      final account = ref.read(accountProvider);
      _uuid = account.uuid;
      _password.text = account.password;
      _username.text = account.username;
      _url.text = account.url;
      _description.text = account.description;
    } else
      _uuid = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Globals.kBackButton,
        title: Text('Add/Update Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Globals.kScreenPadding,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _url,
                  decoration: InputDecoration(
                    hintText: 'URL',
                  ),
                  validator: Globals.kFieldRequiredValidator,
                ),
                Globals.kSizedBox,
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(
                    hintText: 'Username/Email',
                  ),
                  validator: Globals.kFieldRequiredValidator,
                ),
                Globals.kSizedBox,
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon: Icon(hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  obscureText: hidePassword,
                  validator: Globals.kFieldRequiredValidator,
                ),
                Globals.kSizedBox,
                AnimatedOpacity(
                  opacity: _password.text.isEmpty ? 0 : 1,
                  duration: Duration(milliseconds: 300),
                  child: FlutterPasswordStrength(
                    password: _password.text,
                  ),
                ),
                Globals.kSizedBox,
                TextFormField(
                  controller: _description,
                  decoration: InputDecoration(
                    hintText: 'Description...',
                  ),
                  textInputAction: TextInputAction.newline,
                  minLines: 5,
                  maxLines: 5,
                  validator: Globals.kFieldRequiredValidator,
                ),
                Globals.kSizedBox,
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onSubmit,
        label: Text("Submit"),
      ),
    );
  }
}
