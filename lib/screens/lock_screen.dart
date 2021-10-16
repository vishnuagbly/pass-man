import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../components/components.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';
import '../utils/globals.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  SupportState _supportState = SupportState.unknown;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState =
              isSupported ? SupportState.supported : SupportState.unsupported),
        );
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
            'Please authenticate the device to use the application!',
        useErrorDialogs: true,
        stickyAuth: true,
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = "Error - ${e.message}";
      });
      showDialog(
        context: context,
        builder: (_) => CommonAlertDialog(_authorized),
      );
      return;
    }
    if (!mounted) return;

    setState(
        () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  @override
  Widget build(BuildContext context) {
    return (_supportState != SupportState.supported) ||
            (_authorized == 'Authorized') ||
            (kIsWeb)
        ? Container()
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.perm_device_information),
                  label: Text('Click here to unlock!'),
                  style: ElevatedButton.styleFrom(
                    primary: ColorsUtils.kPrimaryColor,
                    onPrimary: ColorsUtils.kTextColor,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                  onPressed: _authenticate,
                ),
              ),
            ),
          );
  }
}
