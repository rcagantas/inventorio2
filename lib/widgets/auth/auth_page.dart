import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/widgets/auth/loading_page.dart';
import 'package:inventorio2/widgets/auth/login_page.dart';
import 'package:inventorio2/widgets/auth/splash_page.dart';
import 'package:inventorio2/widgets/main/main_page.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatelessWidget {
  static const ROUTE = '/auth';
  final locator = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, UserState userState, _) {
        InvState inventoryRepo = locator<InvState>();

        switch (userState.status) {
          case InvStatus.Uninitialized: return SplashPage();
          case InvStatus.Authenticating: return LoadingPage();
          case InvStatus.Unauthenticated:
            inventoryRepo.clear();
            return LoginPage();
          case InvStatus.Authenticated:
            inventoryRepo.loadUserId(userState.invAuth);
            return MainPage();
        }
        return SplashPage();
      },
    );
  }
}
