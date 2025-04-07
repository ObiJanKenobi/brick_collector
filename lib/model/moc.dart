import 'package:brick_collector/common_libs.dart';

import 'collectable_part.dart';

part 'moc.g.dart';

@collection
@JsonSerializable(explicitToJson: true)
class Moc {
  Moc({required this.name});

  Id id = Isar.autoIncrement;

  String name;
  String? imageUrl;

  List<CollectablePart>? parts;

  @Enumerated(EnumType.name)
  PartSort sort = PartSort.nameAsc;
  @Enumerated(EnumType.name)
  PartSort groupSort = PartSort.nameAsc;

  @JsonKey(defaultValue: false)
  bool hideComplete = false;
  @JsonKey(defaultValue: false)
  bool hideCompleteGroup = false;

  int get quantity => parts?.fold(0, (previousValue, element) => (previousValue ?? 0) + element.quantity) ?? 0;

  int get collectedCount => parts?.fold(0, (previousValue, element) => (previousValue ?? 0) + element.collectedCount) ?? 0;

  factory Moc.fromJson(Map<String, dynamic> json) => _$MocFromJson(json);

  Map<String, dynamic> toJson() => _$MocToJson(this);
}

enum PartSort {
  // color,
  nameDesc,
  nameAsc,
  collectedAsc,
  collectedDesc,
  quantityAsc,
  quantityDesc,
}
