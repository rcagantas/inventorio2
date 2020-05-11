import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Image.asset(
          'resources/icons/icon_small.png',
          width: 60.0, height: 60.0,
          key: ObjectKey('icon_small'),
        ),
      ),
    );
  }
}
