// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inv_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvUser _$InvUserFromJson(Map<String, dynamic> json) {
  return InvUser(
    knownInventories:
        (json['knownInventories'] as List)?.map((e) => e as String)?.toList(),
    userId: json['userId'] as String,
    currentInventoryId: json['currentInventoryId'] as String,
    currentVersion: json['currentVersion'] as String,
  );
}

Map<String, dynamic> _$InvUserToJson(InvUser instance) => <String, dynamic>{
      'knownInventories': instance.knownInventories,
      'userId': instance.userId,
      'currentInventoryId': instance.currentInventoryId,
      'currentVersion': instance.currentVersion,
    };
