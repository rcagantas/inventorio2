import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inv_item.g.dart';

@JsonSerializable()
class InvItem {
  final String uuid;
  final String code;
  final String expiry;
  final String dateAdded;
  final String inventoryId;

  @JsonKey(ignore: true) final bool unset;
  @JsonKey(ignore: true) final int redOffset = 7;
  @JsonKey(ignore: true) final int yellowOffset = 30;

  DateTime get expiryDate => expiry == null
      ? DateTime.now()
      : DateTime.parse(expiry);

  DateTime get redAlarm => expiryDate.subtract(Duration(days: redOffset));
  DateTime get yellowAlarm => expiryDate.subtract(Duration(days: yellowOffset));

  bool get withinRed => redAlarm.difference(DateTime.now()).inDays <= 0;
  bool get withinYellow => yellowAlarm.difference(DateTime.now()).inDays <= 0;

  String get heroCode => uuid + '_' + code;

  InvItem ensureValid(String invMetaId) {
    String expiry = this.expiry;
    String dateAdded = this.dateAdded;
    String inventoryId = this.inventoryId;

    if (this.expiry == null) { expiry = DateTime.now().toIso8601String(); }
    if (this.dateAdded == null) {
      dateAdded = DateTime.now()
          .subtract(Duration(days: 365))
          .toIso8601String();
    }
    if (this.inventoryId == null) { inventoryId = invMetaId; }

    return InvItem(
      uuid: this.uuid,
      code: this.code,
      expiry: expiry,
      dateAdded: dateAdded,
      inventoryId: inventoryId
    );
  }

  InvItem({
    @required this.uuid,
    @required this.code,
    this.expiry,
    this.dateAdded,
    this.inventoryId
  }) :
    this.unset = false
  ;

  InvItem.unset() :
    this.uuid = null,
    this.code = null,
    this.expiry = null,
    this.dateAdded = null,
    this.inventoryId = null,
    this.unset = true
  ;

  factory InvItem.fromJson(Map<String, dynamic> json) => _$InvItemFromJson(json);
  Map<String, dynamic> toJson() => _$InvItemToJson(this);

  @override
  bool operator ==(other) {
    return other is InvItem
        && uuid == other.uuid
        && code == other.code
        && expiry == other.expiry
        && dateAdded == other.dateAdded
        && inventoryId == other.inventoryId;
  }
  
  @override
  int get hashCode => hashValues(uuid, code, expiry, dateAdded, inventoryId);
}