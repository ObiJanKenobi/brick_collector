import 'package:brick_collector/common_libs.dart';

part 'cached_source.g.dart';

enum CachedSourceType { set, partlist }

@collection
class CachedSource {
  CachedSource();

  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('externalId')], unique: true, replace: true)
  @Enumerated(EnumType.name)
  late CachedSourceType type;

  late String externalId;
  late String name;
  String? imgUrl;
  int numParts = 0;
  int ownedQuantity = 1;
  int year = 0;
}
