import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/widgets/main/item_card.dart';
import 'package:inventorio2/widgets/main/item_search_delegate.dart';
import 'package:inventorio2/widgets/main/title_card.dart';
import 'package:inventorio2/widgets/scan/scan_page.dart';
import 'package:inventorio2/widgets/settings/settings_page.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {

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
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var begin = Offset(-1, 0.0);
                    var end = Offset.zero;
                    var tween = Tween(begin: begin, end: end);
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                ));
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
              onPressed: () {
                Navigator.pushNamed(context, ScanPage.ROUTE,
                    arguments: invState.selectedInvMeta()
                );
              },
              label: Text('Scan Barcode',
                style: Theme.of(context).accentTextTheme.subtitle1
                    .copyWith(fontWeight: FontWeight.bold),
              )
          ),
          body: invState.selectedInvList().isEmpty ? TitleCard() : ListView.builder(
            itemBuilder: (context, index) {
              InvItem invItem = invState.selectedInvList()[index];
              return ItemCard(invItem);
            },
            itemCount: invState.selectedInvList().length
          ),
        );
      },
    );
  }
}