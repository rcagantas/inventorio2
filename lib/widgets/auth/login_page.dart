import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, UserState userState, _) {
        return Scaffold(
          body: Center(
            child: IntrinsicWidth(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Inventorio', style: Theme.of(context).textTheme.headline3,),
                  Image.asset('resources/icons/icon_transparent.png', width: 150.0, height: 150.0),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      String version = snapshot.hasData
                          ? 'version ${snapshot.data.version} build ${snapshot.data.buildNumber}'
                          : '';
                      return Text('$version', textAlign: TextAlign.center,);
                    },
                  ),
                  Container(height: 50.0,),
                  OutlineButton(
                    key: ObjectKey('google_sign_in'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset('resources/icons/google_logo.png', height: 30.0,),
                        Text('Sign in with Google')
                      ],
                    ),
                    onPressed: () => userState.signInWithGoogle(),
                  ),
                  Visibility(
                    visible: Theme.of(context).platform == TargetPlatform.iOS,
                    replacement: Container(),
                    child: FutureBuilder(
                      key: ObjectKey('apple_sign_in'),
                      future: AppleSignIn.isAvailable(),
                      builder: (context, snapshot) {

                        return OutlineButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image.asset('resources/icons/apple_logo.png', height: 30.0,),
                              Text('Sign in with Apple')
                            ],
                          ),
                          onPressed: () => userState.signInWithApple(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
