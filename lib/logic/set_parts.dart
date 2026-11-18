import 'package:brick_collector/model/cached_inventory_item.dart';
import 'package:brick_collector/model/collectable_part.dart';

/// The parts of one copy of a set, built from its rows in the inventory cache.
class SetPartList {
  SetPartList._(this.parts, this.spareCount);

  /// One entry per part and colour. A set's spares come as separate rows and
  /// are merged in here, so each quantity includes the spares.
  final List<CollectablePart> parts;

  /// How many of the pieces are spares. Zero until a sync has flagged them.
  final int spareCount;

  int get quantity => parts.fold(0, (sum, p) => sum + p.quantity);

  int get collectedCount => parts.fold(0, (sum, p) => sum + p.collectedCount);

  /// The sync stores each row multiplied by the number of [copies] owned;
  /// this divides that back out to the parts of a single set.
  factory SetPartList.fromCache(List<CachedInventoryItem> items, {int copies = 1}) {
    final perCopy = copies < 1 ? 1 : copies;
    final byKey = <String, CollectablePart>{};
    var spares = 0;
    for (final it in items) {
      // Rounded up so an inconsistent row can't drop a part.
      final quantity = (it.quantity / perCopy).ceil();
      if (quantity <= 0) continue;
      if (it.isSpare) spares += quantity;

      final key = CollectablePart.keyFor(it.partNum, it.colorId);
      final existing = byKey[key];
      if (existing != null) {
        existing.quantity += quantity;
        existing.name ??= it.partName;
        continue;
      }
      // No details.imgUrl: it would be read as the image for the whole part
      // group (see AggregatedInventoryRow.toCollectablePart).
      byKey[key] = CollectablePart(
        part: it.partNum,
        name: it.partName,
        color: it.colorId.toString(),
        colorName: it.colorName,
        rgb: it.rgb,
        quantity: quantity,
      );
    }
    return SetPartList._(byKey.values.toList(), spares);
  }
}
