import 'package:json_annotation/json_annotation.dart';

part 'inv_meta.g.dart';

@JsonSerializable()
class InvMeta implements Comparable {
  final String uuid;
  final String name;
  final String createdBy;

  InvMeta({
    this.uuid,
    this.name,
    this.createdBy
  });

  factory InvMeta.fromJson(Map<String, dynamic> json) => _$InvMetaFromJson(json);
  Map<String, dynamic> toJson() => _$InvMetaToJson(this);

  @override
  int compareTo(other) {
    if (other is InvMeta && other != null) {
      return this.name.compareTo(other.name);
    }
    return -1;
  }
}