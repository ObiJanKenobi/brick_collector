import 'package:brick_collector/common_libs.dart';
import 'package:brick_lib/model/rebrickable_color.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'filter_preset.g.dart';

// @collection stays so the Isar schema can still be opened by the
// one-shot migration that uploads pre-Firestore presets to the active group.
@collection
@JsonSerializable(explicitToJson: true)
class FilterPreset {
  FilterPreset({required this.name});

  // Legacy local-only auto-increment id. Excluded from JSON so it never lands
  // in Firestore documents.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Id id = Isar.autoIncrement;

  // Firestore document id once persisted. Same shape as Moc.firestoreId.
  @ignore
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? firestoreId;

  String name;
  String? imageUrl;

  List<RebrickablePartCategory>? categories;
  List<RebrickableColor>? colors;
  String? searchText;

  // Isar's readObjectList returns a fixed-length list, so we always copy into
  // a fresh growable list before mutating.
  addCategory(RebrickablePartCategory val) {
    final list = List<RebrickablePartCategory>.from(categories ?? const []);
    if (!list.any((c) => c.id == val.id)) {
      list.add(val);
    }
    categories = list;
  }

  removeCategory(int categoryId) {
    final list = List<RebrickablePartCategory>.from(categories ?? const [])
      ..removeWhere((c) => c.id == categoryId);
    categories = list;
  }

  addColor(RebrickableColor val) {
    final list = List<RebrickableColor>.from(colors ?? const []);
    if (!list.any((c) => c.id == val.id)) {
      list.add(val);
    }
    colors = list;
  }

  removeColor(int colorId) {
    final list = List<RebrickableColor>.from(colors ?? const [])
      ..removeWhere((c) => c.id == colorId);
    colors = list;
  }

  bool hasColor(int colorId) => colors?.any((c) => c.id == colorId) ?? false;

  factory FilterPreset.fromJson(Map<String, dynamic> json) => _$FilterPresetFromJson(json);

  Map<String, dynamic> toJson() => _$FilterPresetToJson(this);

  factory FilterPreset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final preset = FilterPreset.fromJson(data);
    preset.firestoreId = doc.id;
    return preset;
  }
}
