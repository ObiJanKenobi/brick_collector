import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

import 'collectable_part.dart';

part 'filter_preset.g.dart';

@collection
@JsonSerializable(explicitToJson: true)
class FilterPreset {
  FilterPreset({required this.name});

  Id id = Isar.autoIncrement;

  String name;
  String? imageUrl;

  List<RebrickablePartCategory>? categories;
  List<RebrickableColor>? colors;

  addCategory(RebrickablePartCategory val) {
    categories ??= [];
    if (categories?.contains(val) == false) {
      categories?.add(val);
    }
  }

  // @Enumerated(EnumType.name)
  // PartSort sort = PartSort.nameAsc;
  // @Enumerated(EnumType.name)
  // PartSort groupSort = PartSort.nameAsc;

  factory FilterPreset.fromJson(Map<String, dynamic> json) => _$FilterPresetFromJson(json);

  Map<String, dynamic> toJson() => _$FilterPresetToJson(this);
}
