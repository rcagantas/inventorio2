import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inv_user.g.dart';

@JsonSerializable()
class InvUser {
  final List<String> knownInventories;
  final String userId;
  final String currentInventoryId;
  final String currentVersion;
  @JsonKey(ignore: true) final bool unset;

  InvUser({
    @required this.userId,
    @required this.currentInventoryId,
    @required this.knownInventories,
    this.currentVersion,
  }) :
      this.unset = false
  ;

  InvUser.unset({ @required this.userId }) :
      this.unset = true,
      this.currentInventoryId = null,
      this.currentVersion = null,
      this.knownInventories = []
  ;

  factory InvUser.fromJson(Map<String, dynamic> json) => _$InvUserFromJson(json);
  Map<String, dynamic> toJson() => _$InvUserToJson(this);
}