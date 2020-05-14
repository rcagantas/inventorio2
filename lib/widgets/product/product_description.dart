import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventorio2/models/inv_product.dart';

class ProductDescription extends StatelessWidget {

  final InvProduct product;
  final int productMaxLines;

  ProductDescription({
    this.product,
    this.productMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: product.unset ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Add New Product Information',
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 8.0,),
          Text('${product.code}', style: Theme.of(context).textTheme.caption,),
        ],
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text('${product.brand ?? ''}',
              style: Theme.of(context).textTheme.subtitle2,
              overflow: TextOverflow.ellipsis
          ),
          Text('${product.name ?? ''}',
            style: Theme.of(context).textTheme.subtitle1,
            softWrap: true,
            maxLines: productMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${product.variant ?? ''}',
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}
