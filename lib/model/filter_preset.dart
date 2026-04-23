import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

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
  String? searchText;

  addCategory(RebrickablePartCategory val) {
    categories ??= [];
    if (categories?.contains(val) == false) {
      categories?.add(val);
    }
  }

  addColor(RebrickableColor val) {
    colors ??= [];
    if (colors?.any((c) => c.id == val.id) == false) {
      colors?.add(val);
    }
  }

  removeColor(int colorId) {
    colors?.removeWhere((c) => c.id == colorId);
  }

  bool hasColor(int colorId) => colors?.any((c) => c.id == colorId) ?? false;

  // @Enumerated(EnumType.name)
  // PartSort sort = PartSort.nameAsc;
  // @Enumerated(EnumType.name)
  // PartSort groupSort = PartSort.nameAsc;

  factory FilterPreset.fromJson(Map<String, dynamic> json) => _$FilterPresetFromJson(json);

  Map<String, dynamic> toJson() => _$FilterPresetToJson(this);
}
