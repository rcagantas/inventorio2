import 'dart:math';

import 'package:uuid/uuid.dart';

import 'inv_item.dart';

class InvItemBuilder {

  static final Uuid _uuid = Uuid();

  static String generateUuid() => _uuid.v4();

  String uuid;
  String code;
  String expiry;
  String dateAdded;
  String inventoryId;
  String heroCode;

  DateTime get expiryDate {
    return expiry == null
        ? DateTime.now().add(Duration(days: 30))
        : DateTime.tryParse(expiry);
  }

  set expiryDate(DateTime expiryDateTime) {
    DateTime now = DateTime.now();
    expiryDateTime = expiryDateTime.add(
        Duration(hours: now.hour, minutes: now.minute + 1, seconds: now.second)
    );
    expiry = expiryDateTime.toIso8601String();
  }

  InvItem build() {
    validate();

    return InvItem(
        uuid: uuid,
        code: code,
        expiry: expiry,
        dateAdded: dateAdded,
        inventoryId: inventoryId
    );
  }

  void fromItem(InvItem item) {
    this..uuid = item.uuid
        ..code = item.code
        ..expiry = item.expiry
        ..dateAdded = item.dateAdded
        ..inventoryId = item.inventoryId
        ..heroCode = item.heroCode;
  }

  @override
  String toString() {
    return build().toJson().toString();
  }

  void validate() {
    DateTime now = DateTime.now();
    dateAdded = dateAdded == null
        ? now.toIso8601String()
        : dateAdded;

    expiry = expiry == null
        ? now.add(Duration(days: 30)).toIso8601String()
        : expiry;

    uuid = uuid == null
        ? generateUuid()
        : uuid;
  }
}