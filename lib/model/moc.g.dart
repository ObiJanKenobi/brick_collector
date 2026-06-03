// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Moc _$MocFromJson(Map<String, dynamic> json) => Moc(
      name: json['name'] as String,
    )
      ..imageUrl = json['imageUrl'] as String?
      ..imageBase64 = json['imageBase64'] as String?
      ..sourceUrl = json['sourceUrl'] as String?
      ..parts = (json['parts'] as List<dynamic>?)
          ?.map((e) => CollectablePart.fromJson(e as Map<String, dynamic>))
          .toList()
      ..sort = $enumDecode(_$PartSortEnumMap, json['sort'])
      ..groupSort = $enumDecode(_$PartSortEnumMap, json['groupSort'])
      ..hideComplete = json['hideComplete'] as bool? ?? false
      ..hideCompleteGroup = json['hideCompleteGroup'] as bool? ?? false
      ..shoppingMode = json['shoppingMode'] as bool? ?? false;

Map<String, dynamic> _$MocToJson(Moc instance) => <String, dynamic>{
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'imageBase64': instance.imageBase64,
      'sourceUrl': instance.sourceUrl,
      'parts': instance.parts?.map((e) => e.toJson()).toList(),
      'sort': _$PartSortEnumMap[instance.sort]!,
      'groupSort': _$PartSortEnumMap[instance.groupSort]!,
      'hideComplete': instance.hideComplete,
      'hideCompleteGroup': instance.hideCompleteGroup,
      'shoppingMode': instance.shoppingMode,
    };

const _$PartSortEnumMap = {
  PartSort.nameDesc: 'nameDesc',
  PartSort.nameAsc: 'nameAsc',
  PartSort.collectedAsc: 'collectedAsc',
  PartSort.collectedDesc: 'collectedDesc',
  PartSort.quantityAsc: 'quantityAsc',
  PartSort.quantityDesc: 'quantityDesc',
};
