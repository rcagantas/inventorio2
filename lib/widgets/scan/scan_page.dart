import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_mobile_vision/qr_camera.dart';

class ScanPage extends StatefulWidget {

  static const ROUTE = '/scanBarcode';

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  String _detectedCode;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: QrCamera(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Opacity(
                    opacity: .5,
                    child: Container(
                      height: constraints.maxHeight / 6.5,
                      decoration: BoxDecoration(
                        color: Colors.black
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: .5,
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Center QR / barcode',
                          style: Theme.of(context).textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      height: constraints.maxHeight / 3,
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              qrCodeCallback: (code) {
                if (_detectedCode == null) {
                  _detectedCode = code;
                  Navigator.pop(context, code);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
