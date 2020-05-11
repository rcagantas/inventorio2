import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Stack(
          children: <Widget>[
            Center(child: Image.asset('resources/icons/icon_small.png', width: 60.0, height: 60.0)),
            Center(
              child: Container(
                height: 100.0,
                width: 100.0,
                child: CircularProgressIndicator()
              ),
            )
          ],
        ),
      ),
    );
  }
}
