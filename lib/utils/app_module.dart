import 'package:flutter_modular/flutter_modular.dart';
import 'package:passman/extensions/extensions.dart';
import 'package:passman/screens/screens.dart';

class AppModule extends Module {
  static const kLockScreenRoute = '/lock';

  @override
  List<ModularRoute> get routes => [
        ChildRoute(MPassword.route, child: (_, __) => MPassword()),
        ChildRoute(AuthState.route, child: (_, __) => AuthState()),
        ChildRoute(AddUpdateNote.route, child: (_, __) => AddUpdateNote().auth),
        ChildRoute(AddUpdateAccount.route,
            child: (_, __) => AddUpdateAccount(account: __.data).auth),
        ChildRoute(HomeScreen.route, child: (_, __) => HomeScreen().auth),
        ChildRoute(kLockScreenRoute, child: (_, __) => lockScreen()),
      ];
}
