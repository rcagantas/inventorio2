import 'package:dart_extensions_methods/dart_extensions_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/widgets/product_edit/custom_image_form_field.dart';
import 'package:provider/provider.dart';

class ProductEditPage extends StatefulWidget {

  static const ROUTE = '/productEdit';

  @override
  _ProductEditPageState createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {

  InvProductBuilder productBuilder;
  bool fabValid;

  final _fbKey = GlobalKey<FormBuilderState>();

  final _brandFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _variantFocus = FocusNode();

  static const TOO_LONG = 'Text is too long';
  static const MAX_LEN = 60;

  @override
  void initState() {
    productBuilder = InvProductBuilder();
    checkValidity();
    super.initState();
  }

  void checkValidity() {
    var productValid = productBuilder.name.isNotNullOrEmpty();
    fabValid = _fbKey.currentState?.validate() ?? productValid;
  }

  @override
  Widget build(BuildContext context) {
    productBuilder = ModalRoute.of(context).settings.arguments;
    checkValidity();

    return Consumer<InvState>(
      builder: (context, invState, child) => Scaffold(
        appBar: AppBar(
          title: Text('Edit Product Details'),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: fabValid
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,

          onPressed: () async {
            if (_fbKey.currentState.saveAndValidate()) {
              productBuilder
                ..name = _fbKey.currentState.value['name']
                ..brand = _fbKey.currentState.value['brand']
                ..variant = _fbKey.currentState.value['variant']
                ..imageFile = _fbKey.currentState.value['imageFile'];

              invState.updateProduct(productBuilder);
              Navigator.of(context).pop();
            }

          },
          child: Icon(Icons.cloud_upload),
        ),
        body: FormBuilder(
          key: _fbKey,
          autovalidate: true,
          initialValue: {
            'name': productBuilder.name,
            'brand': productBuilder.brand,
            'variant': productBuilder.variant,
            'imageFile': null,
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {

                var orientation = MediaQuery.of(context).orientation;

                var children = <Widget>[
                  CustomImageFormField(
                    attribute: 'imageFile',
                    heroCode: productBuilder.heroCode,
                    initialUrl: productBuilder.imageUrl,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('${productBuilder.code}',
                        style: Theme.of(context).textTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                      FormBuilderTextField(
                        attribute: 'brand',
                        focusNode: _brandFocus,
                        decoration: InputDecoration(labelText: 'Brand name'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (value) => FocusScope.of(context).requestFocus(_nameFocus),
                        validators: [
                          FormBuilderValidators.maxLength(MAX_LEN, errorText: TOO_LONG),
                        ],
                      ),
                      FormBuilderTextField(
                        attribute: 'name',
                        focusNode: _nameFocus,
                        decoration: InputDecoration(labelText: 'Product Name'),
                        onChanged: (value) {
                          setState(() {
                            checkValidity();
                          });
                        },
                        textCapitalization: TextCapitalization.words,
                        autovalidate: true,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (value) => FocusScope.of(context).requestFocus(_variantFocus),
                        validators: [
                          FormBuilderValidators.required(errorText: 'Please set a product name'),
                          FormBuilderValidators.maxLength(MAX_LEN, errorText: TOO_LONG),
                        ],
                      ),
                      FormBuilderTextField(
                        attribute: 'variant',
                        focusNode: _variantFocus,
                        decoration: InputDecoration(labelText: 'Variant/Flavor/Volume'),
                        textCapitalization: TextCapitalization.words,
                        autovalidate: true,
                        textInputAction: TextInputAction.next,
                        validators: [
                          FormBuilderValidators.maxLength(MAX_LEN, errorText: TOO_LONG),
                        ],
                      ),
                    ],
                  )
                ];

                return GridView.count(
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  crossAxisCount: orientation == Orientation.portrait? 1 : 2,
                  childAspectRatio: 1.20,
                  children: children,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
