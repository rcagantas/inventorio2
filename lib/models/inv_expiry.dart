import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_product.dart';

class InvExpiry implements Comparable {
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
      + '${DateFormat.MMM().format(item.expiryDate)} ${item.expiryDate.day}';
  DateTime get alertDate => item.expiryDate.subtract(Duration(days: daysOffset));

  @override
  String toString() => '[$alertDate] $title $body';

  @override
  int compareTo(other) {
    if (other is InvExpiry) {
      return this.alertDate.compareTo(other.alertDate);
    }
    return -1;
  }
}