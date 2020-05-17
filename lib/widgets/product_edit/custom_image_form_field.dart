import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_extensions_methods/dart_extensions_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';

class CustomImageFormField extends StatefulWidget {
  final String heroCode;
  final String initialUrl;
  final String attribute;

  CustomImageFormField({
    @required this.attribute,
    @required this.heroCode,
    @required this.initialUrl,
  });

  @override
  _CustomImageFormFieldState createState() => _CustomImageFormFieldState();
}

class _CustomImageFormFieldState extends State<CustomImageFormField> {

  File imageFile;

  @override
  Widget build(BuildContext context) {

    var formState = FormBuilder.of(context);

    var placeHolder = Image.asset(
      'resources/icons/icon_small.png',
      fit: BoxFit.cover
    );

    return Hero(
      tag: widget.heroCode,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),

        child: Stack(
          children: <Widget>[
            Positioned.fill(child: placeHolder),
            Positioned.fill(child: Center(child: Text('Tap To Set Image', style: Theme.of(context).textTheme.headline6,))),
            Positioned.fill(
              child: this.widget.initialUrl.isNotNullOrEmpty() ? CachedNetworkImage(
                imageUrl: this.widget.initialUrl, fit: BoxFit.cover,
                placeholder: (context, url) => placeHolder,
                errorWidget: (context, url, error) => placeHolder,
              ) : Container()
            ),
            Positioned(bottom: 8.0, left: 8.0, child: Icon(Icons.camera_alt)),
            Positioned.fill(
              child: imageFile == null? Container() : Image.asset(imageFile.path, fit: BoxFit.cover,)
            ),
            Positioned.fill(
              child: new Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
                    if (imageFile != null) {
                      setState(() {
                        formState.setAttributeValue(widget.attribute, imageFile);
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}