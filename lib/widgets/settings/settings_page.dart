import 'package:cached_network_image/cached_network_image.dart';
import 'package:dart_extensions_methods/dart_extensions_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/widgets/inventory_edit/inventory_edit_page.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  static const ROUTE = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'),),
      body: Column(
        children: <Widget>[
          Consumer<UserState>(
            builder: (context, userState, child) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).bottomAppBarColor,
                backgroundImage: userState.invAuth.photoUrl.isNullOrEmpty()
                    ? AssetImage('resources/icons/icon_small.png')
                    : CachedNetworkImageProvider(userState.invAuth.photoUrl),
              ),
              title: Text(userState.invAuth.displayName.isNullOrEmpty()
                  ? 'Sign-in'
                  : '${userState.invAuth.displayName}'),
              subtitle: Text(userState.invAuth.email ?? ''),
              trailing: IconButton(
                tooltip: 'Log Out',
                icon: Icon(Icons.exit_to_app),
                onPressed: () {
                  userState.signOut();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Wrap(
            children: <Widget>[
              FlatButton(
                onPressed: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Icon(Icons.add),
                    Text('New')
                  ],
                ),
              ),
              FlatButton(
                onPressed: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(FontAwesomeIcons.qrcode),
                    Text('Scan')
                  ],
                ),
              ),
              FlatButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, InventoryEditPage.ROUTE,);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Icon(Icons.edit),
                    Text('Edit')
                  ],
                ),
              ),

            ],
          ),
          Expanded(
            child: Consumer<InvState>(
              builder: (context, invState, child) => ListView.builder(
                itemCount: invState.invMetas.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text('${invState.invMetas[index].name}'),
                  subtitle: Text('${invState.invMetas[index].uuid}'),
                  selected: invState.invMetas[index] == invState.selectedInvMeta(),
                  onTap: () {
                    Navigator.pop(context);
                    invState.selectInvMeta(invState.invMetas[index]);
                  },
                  onLongPress: () {},
                ),
              )
            ),
          )
        ],
      ),
    );
  }
}
