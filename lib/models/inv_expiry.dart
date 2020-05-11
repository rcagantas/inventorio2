import 'dart:math' as math;

import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_product.dart';

class InvExpiry {
  final InvItem item;
  final InvProduct product;
  final int daysOffset;

  InvExpiry({
    this.item,
    this.product,
    this.daysOffset,
  });

  int get scheduleId => '$item.uuid/$daysOffset'.hashCode % ((math.pow(2, 31)) - 1);
  String get title => product.stringRepresentation;
  String get body => 'is about to expire within $daysOffset days on '
      + '${item.expiryDate.year} ${item.expiryDate.month} ${item.expiryDate.day}';
  DateTime get alertDate => item.expiryDate.subtract(Duration(days: daysOffset));

  @override
  String toString() => '$title $body';
}