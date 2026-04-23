import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/cached_source.dart';

part 'cached_inventory_item.g.dart';

@collection
class CachedInventoryItem {
  CachedInventoryItem();

  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late CachedSourceType sourceType;

  late String sourceExternalId;

  @Index(composite: [CompositeIndex('colorId')])
  late String partNum;

  String? partName;
  int? partCategoryId;
  late int colorId;
  String? colorName;
  String? rgb;
  String? imgUrl;
  int quantity = 0;
  bool isSpare = false;
}
