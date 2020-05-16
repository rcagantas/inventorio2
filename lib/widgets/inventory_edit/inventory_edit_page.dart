import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class InventoryEditPage extends StatefulWidget {

  static const ROUTE = '/editInventory';

  @override
  _InventoryEditPageState createState() => _InventoryEditPageState();
}

class _InventoryEditPageState extends State<InventoryEditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Inventory'),),
      body: Column(
        children: <Widget>[

        ],
      ),
    );
  }
}
