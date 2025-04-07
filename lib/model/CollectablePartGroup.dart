import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/collectable_part.dart';

class CollectablePartGroup extends PartGroup<CollectablePart> {
  int get collectedCount => parts.isNotEmpty ? parts.map((e) => e.collectedCount).reduce((value, element) => value + element) : 0;
}
