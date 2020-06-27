import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/widgets/expiry/expiry_page.dart';
import 'package:inventorio2/widgets/main/item_card.dart';
import 'package:inventorio2/widgets/main/item_search_delegate.dart';
import 'package:inventorio2/widgets/main/title_card.dart';
import 'package:inventorio2/widgets/scan/scan_page.dart';
import 'package:inventorio2/widgets/settings/settings_page.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {

  static const ROUTE = '/main';

  final Map<InvSort, Icon> iconMap = {
    InvSort.EXPIRY: Icon(Icons.sort),
    InvSort.DATE_ADDED: Icon(Icons.calendar_today),
    InvSort.PRODUCT: Icon(Icons.sort_by_alpha),
  };

  @override
  Widget build(BuildContext context) {

    return Consumer<InvState>(
      builder: (context, invState, child) {

        Icon sortIcon = iconMap[invState.sortingKey];

        return Scaffold(
          appBar: AppBar(
            title: Text('${invState.selectedInvMeta().name}'),
            leading: FlatButton(
              padding: EdgeInsets.all(10.0),
              child: Image.asset('resources/icons/icon_small_white.png', fit: BoxFit.cover,),
              onPressed: () async {
                await Navigator.pushNamed(context, SettingsPage.ROUTE);
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: sortIcon,
                onPressed: () {
                  invState.toggleSort();
                },
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ItemSearchDelegate()
                  );
                },
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {

              if (!await ScanPage.hasPermissions(context)) {
                return;
              }

              var popped = await Navigator.pushNamed(context, ScanPage.ROUTE);
              String code = popped?.toString() ?? '';

              if (code.isNotEmpty) {
                var builder = InvItemBuilder(
                  code: code,
                  inventoryId: invState.selectedInvMeta().uuid
                );

                invState.fetchProduct(code);

                await Navigator.pushNamed(context, ExpiryPage.ROUTE,
                arguments: builder.build()
                );
              }
            },
            label: Text('Scan Barcode',
              style: Theme.of(context).accentTextTheme.subtitle1
                  .copyWith(fontWeight: FontWeight.bold),
            )
          ),
          body: Visibility(
            visible: !invState.isLoading(),
            child: Visibility(
              visible: invState.selectedInvList().isNotEmpty,
              child: ListView.builder(
                itemCount: invState.selectedInvList().length,
                itemBuilder: (context, index) {
                  var item = invState.selectedInvList()[index];
                  return ItemCard(item);
                },
              ),
              replacement: TitleCard(),
            ),
            replacement: SizedBox(
              height: 3.0,
              child: LinearProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}