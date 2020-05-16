import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:inventorio2/models/inv_item_builder.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/models/inv_product_builder.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/widgets/product/product_description.dart';
import 'package:inventorio2/widgets/product/product_image.dart';
import 'package:inventorio2/widgets/product_edit/product_edit_page.dart';
import 'package:provider/provider.dart';

class ExpiryPage extends StatefulWidget {

  static const ROUTE = '/expiry';

  @override
  _ExpiryPageState createState() => _ExpiryPageState();
}

class _ExpiryPageState extends State<ExpiryPage> {

  InvItemBuilder itemBuilder;

  @override
  void initState() {
    itemBuilder = InvItemBuilder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    itemBuilder.fromItem(ModalRoute.of(context).settings.arguments);

    return Consumer<InvState>(
      builder: (context, invState, child) {

        return Scaffold(
          appBar: AppBar(title: Text('Set Expiry Date'),),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.save),
            onPressed: () async {

              var product = invState.getProduct(itemBuilder.code);
              if (product.unset) {
                await Navigator.pushNamed(context, ProductEditPage.ROUTE,
                  arguments: InvProductBuilder.fromProduct(
                    InvProduct.unset(code: itemBuilder.code),
                    itemBuilder.heroCode,
                  )
                );
              }

              itemBuilder.inventoryId = invState.selectedInvMeta().uuid;
              invState.updateItem(itemBuilder.build());
              Navigator.pop(context);
            },
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {

              var media = MediaQuery.of(context);
              var datePicker = DatePickerWidget(
                minDateTime: itemBuilder.expiryDate.subtract(Duration(days: 365)),
                maxDateTime: itemBuilder.expiryDate.add(Duration(days: 365 * 10)),
                onMonthChangeStartWithFirstDate: true,
                initialDateTime: itemBuilder.expiryDate,
                dateFormat: 'yyyy MMMM d',
                locale: DATETIME_PICKER_LOCALE_DEFAULT,

                onChange: (dateTime, selectedIndex) {
                  itemBuilder.expiryDate = dateTime.add(Duration(minutes: 2));
                },

                pickerTheme: DateTimePickerTheme(
                  showTitle: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  itemTextStyle: Theme.of(context).textTheme.headline5,
                  itemHeight: 50.0 * media.textScaleFactor,
                ),
              );

              var borderRadius = const BorderRadius.all(Radius.circular(10.0));
              var product = invState.getProduct(itemBuilder.code);

              return Wrap(
                children: <Widget>[
                  Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(borderRadius: borderRadius,),
                    child: FlatButton(
                      padding: EdgeInsets.all(0.0),
                      onPressed: () async {
                        await Navigator.pushNamed(context, ProductEditPage.ROUTE,
                          arguments: InvProductBuilder.fromProduct(
                            invState.getProduct(itemBuilder.code),
                            itemBuilder.heroCode
                          )
                        );
                      },
                      child: SizedBox(
                        height: media.size.height / 4,
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: ProductImage(
                                imageUrl: product.imageUrl,
                                heroCode: itemBuilder.heroCode,
                                borderRadius: borderRadius,
                              )
                            ),
                            Flexible(child: ProductDescription(
                              product: product,
                              productMaxLines: 5,)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: media.size.height / 3,
                    child: datePicker,
                  )
                ],
              );
            }
          ),
        );
      },
    );
  }
}
